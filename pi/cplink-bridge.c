/* cplink-bridge.c - the CPC-CPLink (and CPLink2) card's Pi side: its FIFOs to a TCP socket on
 * 127.0.0.1, so cosd.js (or anything) talks to the CPC as to a stream.
 *
 *   cplink-bridge [port]          (default 7001)
 *     port      the FIFO stream: the CPC's bytes out, the bytes written in go to the CPC
 *     port + 1  the CPLink2's Pi ROM: a connection's bytes (32K at most) written to PI ROM 1, 2
 *               (ROM 32 / 33 to the CPC, read at &C000) - "OK n" back when written, after the CPC
 *               read the last ones (RRD1 / RRD2). The original CPLink has no Pi ROM.
 *
 * The GPIO (BCM numbers, the cards' header): D0-D7 2 3 4 7 8 9 10 11, DIR 17 (in: the CPC's FIFO
 * has room), DOR 23 (in: a byte from the CPC waiting), SI 18 (out: a byte in), SOB 22 (out: a byte
 * taken), WNR 24 (out: the Pi writing), RNF 26 (out, CPLink2: to the ROM, not the FIFO - pulled
 * low on the card: the original card's behaviour), RRD1 19, RRD2 13 (in, CPLink2: the CPC has read
 * ROM 1 / 2). Registers through /dev/gpiomem (no root, no library): the BCM2835 / 2837 / 2711
 * GPIO block - GPFSEL at 0, GPSET0 at #1C, GPCLR0 at #28, GPLEV0 at #34.
 * Settle times (the CPLink2's): RNF 1000 us, WNR 300 ns, data 300 ns, SI high 500 ns, low 300 ns.
 *
 * Build on the Pi:  cc -O2 -o cplink-bridge cplink-bridge.c
 * (c) 2026 Cyborg Unicorn Pty Ltd - MIT License
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <poll.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>

#define P_DIR  17
#define P_DOR  23
#define P_SI   18
#define P_SOB  22
#define P_WNR  24
#define P_RNF  26
#define P_RRD1 19
#define P_RRD2 13
static const int D[8] = { 2, 3, 4, 7, 8, 9, 10, 11 };
static volatile uint32_t *g;

static void ns(long n)                  /* a short wait: spun, nanosleep is too coarse */
{
	struct timespec a, b;
	clock_gettime(CLOCK_MONOTONIC, &a);
	do { clock_gettime(CLOCK_MONOTONIC, &b); } while ((b.tv_sec - a.tv_sec) * 1000000000L + (b.tv_nsec - a.tv_nsec) < n);
}
static void mode(int p, int out)       /* GPFSEL: 000 in, 001 out */
{
	volatile uint32_t *r = g + p / 10;
	int s = (p % 10) * 3;
	*r = (*r & ~(7u << s)) | ((out ? 1u : 0u) << s);
}
static void set(int p, int v) { if (v) { g[0x1C / 4] = 1u << p; } else { g[0x28 / 4] = 1u << p; } }
static int  get(int p) { return (g[0x34 / 4] >> p) & 1; }
static void bus(int out) { int i; for (i = 0; i < 8; i++) { mode(D[i], out); } }
static void put8(int v)
{
	uint32_t s = 0, c = 0;
	int i;
	for (i = 0; i < 8; i++) { if (v & (1 << i)) { s |= 1u << D[i]; } else { c |= 1u << D[i]; } }
	g[0x1C / 4] = s; g[0x28 / 4] = c;
}
static int get8(void)
{
	uint32_t l = g[0x34 / 4];
	int i, v = 0;
	for (i = 0; i < 8; i++) { if (l & (1u << D[i])) { v |= 1 << i; } }
	return v;
}

static void setup(void)
{
	int fd = open("/dev/gpiomem", O_RDWR | O_SYNC);
	if (fd < 0) { perror("/dev/gpiomem"); exit(1); }
	g = (volatile uint32_t *)mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (g == MAP_FAILED) { perror("mmap"); exit(1); }
	bus(0);                              /* idle: the data lines high impedance */
	mode(P_DIR, 0); mode(P_DOR, 0); mode(P_RRD1, 0); mode(P_RRD2, 0);
	mode(P_SI, 1); set(P_SI, 0);
	mode(P_SOB, 1); set(P_SOB, 0);
	mode(P_WNR, 1); set(P_WNR, 0);
	mode(P_RNF, 1); set(P_RNF, 0);       /* the FIFO (an original card: no such pin, harmless) */
}

/* a byte from the CPC (DOR high): read, SOB pulsed, DOR given time to fall */
static int fifo_in(void)
{
	int v = get8(), t = 50;
	set(P_SOB, 1); ns(300); set(P_SOB, 0);
	while (get(P_DOR) && t--) { ns(20); }
	return v;
}
/* a byte to the CPC (DIR high): WNR, the data, SI pulsed, back to idle */
static void fifo_out(int v)
{
	set(P_WNR, 1); ns(300);
	bus(1); put8(v); ns(300);
	set(P_SI, 1); ns(500); set(P_SI, 0); ns(300);
	bus(0);
	set(P_WNR, 0);
}
/* n bytes to the Pi ROM (CPLink2): after the CPC read the last (RRD1 / RRD2 - 5 s at most) */
static int rom_write(const uint8_t *b, int n)
{
	int i, t;
	struct timespec a, c;
	clock_gettime(CLOCK_MONOTONIC, &a);
	for (;;)
	{
		if (get(P_RRD1) && (n <= 16384 || get(P_RRD2))) { break; }
		clock_gettime(CLOCK_MONOTONIC, &c);
		if (c.tv_sec - a.tv_sec > 5) { fprintf(stderr, "cplink-bridge: the CPC hasn't read the ROM (5 s) - written over\n"); break; }
		ns(100000);
	}
	set(P_RNF, 1); ns(1000000);
	set(P_WNR, 1); ns(300);
	bus(1);
	for (i = 0; i < n; i++)
	{
		for (t = 100000; !get(P_DIR) && t; t--) { ns(100); }
		put8(b[i]); ns(300);
		set(P_SI, 1); ns(500); set(P_SI, 0); ns(300);
	}
	bus(0);
	set(P_WNR, 0); ns(300);
	set(P_RNF, 0);
	return n;
}

static int listen_on(int port)
{
	int s = socket(AF_INET, SOCK_STREAM, 0), one = 1;
	struct sockaddr_in a;
	setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
	memset(&a, 0, sizeof a);
	a.sin_family = AF_INET; a.sin_port = htons(port); a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
	if (bind(s, (struct sockaddr *)&a, sizeof a) < 0 || listen(s, 1) < 0) { perror("bind"); exit(1); }
	fcntl(s, F_SETFL, O_NONBLOCK);
	return s;
}

int main(int argc, char *argv[])
{
	int port = argc > 1 ? atoi(argv[1]) : 7001;
	int ls = listen_on(port), lr = listen_on(port + 1), c = -1, idle = 0, one = 1;
	static uint8_t out[8192], rom[32768];
	int on = 0, op = 0;                  /* bytes waiting for the CPC: out[op .. on) */
	setup();
	fprintf(stderr, "cplink-bridge: the FIFO on 127.0.0.1:%d, the Pi ROM on %d\n", port, port + 1);
	for (;;)
	{
		int busy = 0;
		if (c < 0)
		{
			c = accept(ls, NULL, NULL);
			if (c >= 0) { fcntl(c, F_SETFL, O_NONBLOCK); setsockopt(c, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one); on = op = 0; }
		}
		/* the CPC's bytes, in a burst, to the socket */
		if (get(P_DOR))
		{
			uint8_t b[256];
			int n = 0;
			while (n < 256 && get(P_DOR)) { b[n++] = (uint8_t)fifo_in(); }
			if (c >= 0 && send(c, b, n, MSG_NOSIGNAL) < 0 && errno != EAGAIN) { close(c); c = -1; }
			busy = 1;
		}
		/* the socket's bytes to the CPC while its FIFO has room */
		if (c >= 0 && op == on)
		{
			int n = recv(c, out, sizeof out, 0);
			if (n > 0) { on = n; op = 0; }
			else if (n == 0 || (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK)) { close(c); c = -1; }
		}
		while (op < on && get(P_DIR)) { fifo_out(out[op++]); busy = 1; }
		/* a ROM write (CPLink2) */
		{
			int r = accept(lr, NULL, NULL);
			if (r >= 0)
			{
				int n = 0, k;
				char ok[32];
				while (n < (int)sizeof rom && (k = recv(r, rom + n, sizeof rom - n, 0)) > 0) { n += k; }
				rom_write(rom, n);
				snprintf(ok, sizeof ok, "OK %d\n", n);
				send(r, ok, strlen(ok), MSG_NOSIGNAL);
				close(r);
				busy = 1;
			}
		}
		if (busy) { idle = 0; } else if (++idle > 2000) { usleep(200); }   /* quiet: give the Pi back */
	}
	return 0;
}
