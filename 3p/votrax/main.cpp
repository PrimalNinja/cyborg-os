// main.cpp - the SC-01 (Votrax) as a program: phoneme bytes on stdin (bits 0-5 the phone, bits
// 6-7 the inflection), 16-bit mono PCM on stdout at the chip's sample rate (the main clock / 18:
// 720 kHz gives 40000 Hz). Run:  votrax SC01A.BIN | aplay -f S16_LE -r 40000 -c 1
// With no ROM file (the chip's 512-byte internal ROM, its own), it writes nothing and exits 2.
// (c) 2026 Cyborg Unicorn Pty Ltd - MIT License; the emulation is MAME's votrax.cpp (BSD-3-Clause)
#include "emu.h"
#include "votrax.h"
#include <unistd.h>
#include <fcntl.h>

static const u32 MAINCLOCK = 720000;

int main(int argc, char **argv)
{
	if (argc < 2) { fprintf(stderr, "votrax ROMFILE (SC01A.BIN, 512 bytes)\n"); return 2; }
	FILE *f = fopen(argv[1], "rb");
	if (!f) { return 2; }					// no ROM: nothing out
	std::vector<u8> rom(512);
	size_t n = fread(rom.data(), 1, 512, f);
	fclose(f);
	if (n != 512) { return 2; }
	machine_config cfg;
	votrax_sc01a_device dev(cfg, "sc01", nullptr, MAINCLOCK);
	dev.m_rom_file(rom);
	dev.start_();
	u32 rate = MAINCLOCK / 18;
	double tick = 1.0 / rate;
	const int CHUNK = 400;					// 10 ms of samples a round
	std::vector<s16> pcm(CHUNK);
	int fd = fileno(stdin);
	fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK);
	int idle = 0;
	for (;;)
	{
		u8 b;
		ssize_t got = read(fd, &b, 1);
		if (got == 1)
		{
			dev.inflection_w((b >> 6) & 3);
			dev.write(b & 0x3f);
			idle = 0;
		}
		else if (got == 0) { break; }		// stdin closed: done
		// run the timer and the stream for one chunk
		for (int i = 0; i < CHUNK; i++)
		{
			dev.step_timer();
			dev.machine().now += tick;
		}
		dev.render(pcm.data(), CHUNK);
		bool silent = true;
		for (int i = 0; i < CHUNK && silent; i++) { if (pcm[i] > 16 || pcm[i] < -16) { silent = false; } }
		if (!silent || idle < 100) { fwrite(pcm.data(), 2, CHUNK, stdout); fflush(stdout); }
		if (silent) { idle++; if (idle > 100) { usleep(10000); } }		// nothing to say: breathe, keep the pipe quiet
	}
	return 0;
}
