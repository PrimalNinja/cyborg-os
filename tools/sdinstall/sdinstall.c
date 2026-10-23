#define _FILE_OFFSET_BITS 64
#define _DEFAULT_SOURCE
/* sdinstall.c - CyborgOS's installer for an SD card / IDE image (or a plain folder): what INSTALL.BAS does on the CPC
 * (the discs into CYBORGOS/, CYBORGOS/C/, CYBORGOS/HELP/ on a UniDOS device), done here, straight
 * into a FAT image - from the CPC's disc images, or from a folder on this machine.
 *
 *   sdinstall IMAGE --dsk cos-disk1.dsk cos-disk2.dsk ... [/DEST/PATH]
 *       the CPC's discs (CPCEMU .DSK, AMSDOS data format): INSTALL.BAS on the first one says what
 *       goes where (its DATA list: "#n" the disc, "C/NAME.CYB", "HELP/NAME.HLP", "NAME" ...), the
 *       files as they are (AMSDOS headers and all, as |COPY copies them); a disc given in any
 *       order, one not given skipped with its files
 *   sdinstall IMAGE SRCDIR [/DEST/PATH]
 *       a folder's files and folders (CyborgOS-Next: tools/sdinstall/dist.sh lays one out)
 *   the default destination /CYBORGOS. IMAGE may be a folder on this machine instead: the files
 *   are written into it as they are (the discs unpacked into a folder tree for a card copied by hand)
 *
 * IMAGE: a raw image - with an MBR (partition 1 is used: a ZEsarUX tbblue.mmc, a dd of a card) or
 * a bare FAT volume - or WinAPE's IDE image (.ide: "BITWISE DRIVE IMAGE FILE", a sparse file with
 * a block map, read and written through the map). FAT12, FAT16 and FAT32. Files go under the
 * destination path (made if it isn't there), each over one of its name already there. Names
 * are 8.3 (capitals; "CYBORGOS.NEX", "DIR.CYB"): a name that isn't is an error, as CyborgOS's
 * files all are and CP/M wants. No long names are written. Dates: now.
 * Build: cc -O2 -o sdinstall sdinstall.c
 * (c) 2026 Cyborg Unicorn Pty Ltd - MIT License */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <strings.h>
#include <stdint.h>
#include <time.h>
#include <sys/stat.h>
#include <dirent.h>
#include <ctype.h>

static FILE *img;
static uint32_t part_lba;           /* the volume's first sector in the image */
static uint16_t bps;                /* bytes a sector */
static uint8_t spc;                 /* sectors a cluster */
static uint16_t reserved, root_entries;
static uint8_t nfats;
static uint32_t fat_sectors, total_sectors, root_cluster, fsinfo_sector;
static uint32_t fat_start, root_start, data_start, clusters;   /* sectors; data_start = cluster 2 */
static int fat_type;                /* 12, 16, 32 */
static uint8_t *fat;                /* the FAT, read whole, written back at the end */
static uint32_t next_free = 2;
static uint32_t eoc;

static void die(const char *m) { fprintf(stderr, "sdinstall: %s\n", m); exit(1); }
static uint16_t rd16(const uint8_t *p) { return p[0] | p[1] << 8; }
static uint32_t rd32(const uint8_t *p) { return p[0] | p[1] << 8 | p[2] << 16 | (uint32_t)p[3] << 24; }
static void wr16(uint8_t *p, uint16_t v) { p[0] = v; p[1] = v >> 8; }
static void wr32(uint8_t *p, uint32_t v) { p[0] = v; p[1] = v >> 8; p[2] = v >> 16; p[3] = v >> 24; }

/* ---- WinAPE's IDE image ("BITWISE DRIVE IMAGE FILE"): a sparse image - a 512 byte header, then
 * 512 byte blocks: a 4 level tree of 128 entry tables (32 bit block numbers; the root is block 1)
 * maps a disc sector to the block holding it (the disc's sector s: root[s >> 21] -> [s >> 14 & 127]
 * -> [s >> 7 & 127] -> [s & 127] -> its block), so a 10GB drive is a 17MB file. An entry 0 or
 * #FFFF0000 is a sector never written (reads as zeros); a write to one gets a new block at the
 * file's end (and new tables on the way). The header is left as it is. */
static int sparse;
static uint32_t file_blocks;
static void sp_read_block(uint32_t b, uint8_t *buf)
{
    if (fseeko(img, (off_t)b * 512, SEEK_SET) || fread(buf, 512, 1, img) != 1) die("read failed (image block)");
}
static void sp_write_block(uint32_t b, const uint8_t *buf)
{
    if (fseeko(img, (off_t)b * 512, SEEK_SET) || fwrite(buf, 512, 1, img) != 1) die("write failed (image block)");
    if (b >= file_blocks) file_blocks = b + 1;
}
static int sp_unset(uint32_t e) { return e == 0 || e == 0xFFFF0000 || e == 0xFFFFFFFF; }
/* the block holding disc sector s: 0 when none (alloc: one made, with the tables it needs) */
static uint32_t sp_block(uint32_t s, int alloc)
{
    uint32_t b = 1; uint8_t t[512];
    for (int lvl = 0; lvl < 4; lvl++) {
        int ix = (s >> (21 - 7 * lvl)) & 127;
        sp_read_block(b, t);
        uint32_t e = rd32(t + 4 * ix);
        if (sp_unset(e)) {
            if (!alloc) return 0;
            e = file_blocks;                 /* a new table (0 entries) or data block, at the end */
            uint8_t *z = calloc(512, 1);
            if (lvl == 2) for (int i = 0; i < 128; i++) wr32(z + 4 * i, 0xFFFF0000);   /* (the data level tables use #FFFF0000) */
            sp_write_block(e, z); free(z);
            wr32(t + 4 * ix, e); sp_write_block(b, t);
        }
        b = e;
    }
    return b;
}
static void read_sectors(uint32_t s, uint32_t n, uint8_t *buf)
{
    if (sparse) {
        for (uint32_t i = 0; i < n; i++) {
            uint32_t b = sp_block(part_lba + s + i, 0);
            if (b) sp_read_block(b, buf + i * 512); else memset(buf + i * 512, 0, 512);
        }
        return;
    }
    if (fseeko(img, (off_t)(part_lba + s) * bps, SEEK_SET) || fread(buf, bps, n, img) != n) die("read failed");
}
static void write_sectors(uint32_t s, uint32_t n, const uint8_t *buf)
{
    if (sparse) {
        uint8_t old[512];
        for (uint32_t i = 0; i < n; i++) {
            uint32_t b = sp_block(part_lba + s + i, 0);
            if (b) { sp_read_block(b, old); if (!memcmp(old, buf + i * 512, 512)) continue; }
            else { int z = 1; for (int k = 0; k < 512; k++) if (buf[i * 512 + k]) { z = 0; break; } if (z) continue; }   /* (zeros into a sector never written: nothing to do) */
            sp_write_block(sp_block(part_lba + s + i, 1), buf + i * 512);
        }
        return;
    }
    if (fseeko(img, (off_t)(part_lba + s) * bps, SEEK_SET) || fwrite(buf, bps, n, img) != n) die("write failed");
}

/* ---- the FAT */
static uint32_t fat_get(uint32_t c)
{
    if (fat_type == 32) return rd32(fat + c * 4) & 0x0FFFFFFF;
    if (fat_type == 16) return rd16(fat + c * 2);
    uint32_t o = c + c / 2, v = rd16(fat + o);
    return (c & 1) ? v >> 4 : v & 0xFFF;
}
static void fat_set(uint32_t c, uint32_t v)
{
    if (fat_type == 32) wr32(fat + c * 4, (rd32(fat + c * 4) & 0xF0000000) | (v & 0x0FFFFFFF));
    else if (fat_type == 16) wr16(fat + c * 2, v);
    else {
        uint32_t o = c + c / 2, w = rd16(fat + o);
        w = (c & 1) ? (w & 0x000F) | (v << 4) : (w & 0xF000) | (v & 0xFFF);
        wr16(fat + o, w);
    }
}
static int is_eoc(uint32_t v) { return v >= (fat_type == 32 ? 0x0FFFFFF8u : fat_type == 16 ? 0xFFF8u : 0xFF8u); }
static uint32_t cluster_sector(uint32_t c) { return data_start + (c - 2) * spc; }

static uint32_t alloc_cluster(void)
{
    uint32_t c, n;
    for (n = 0; n < clusters; n++) {
        c = next_free + n; if (c >= clusters + 2) c -= clusters;
        if (c < 2) continue;
        if (fat_get(c) == 0) {
            fat_set(c, eoc); next_free = c + 1;
            uint8_t *z = calloc(spc, bps); write_sectors(cluster_sector(c), spc, z); free(z);
            return c;
        }
    }
    die("the image is full");
    return 0;
}
static void free_chain(uint32_t c)
{
    while (c >= 2 && !is_eoc(c)) { uint32_t n = fat_get(c); fat_set(c, 0); c = n; }
}

/* ---- directories. A directory is its entries: the root of FAT12/16 is a fixed region, any other
 * a cluster chain. dir_walk calls f for each entry (32 bytes, in place in a sector buffer it may
 * change); f returns 1 to stop (the sector is written back then) */
typedef struct { uint32_t first_cluster; int is_fixed_root; char path[1024]; } dir_t;
static int folder_mode;             /* the "image" is a folder on this machine: the files go there as they are */

static int dir_find_slot_or_entry(dir_t *d, const char *name83, uint8_t *entry_out, uint32_t *sec_out, int *off_out, int want_free)
{
    uint8_t *buf = malloc(bps);
    uint32_t sec, nsec, c = d->first_cluster;
    int found = 0;
    for (;;) {
        if (d->is_fixed_root) { sec = root_start; nsec = (root_entries * 32 + bps - 1) / bps; }
        else { sec = cluster_sector(c); nsec = spc; }
        for (uint32_t s = 0; s < nsec && !found; s++) {
            read_sectors(sec + s, 1, buf);
            for (int o = 0; o < bps; o += 32) {
                uint8_t *e = buf + o;
                if (want_free) {
                    if (e[0] == 0 || e[0] == 0xE5) { found = 1; }
                } else {
                    if (e[0] == 0) break;
                    if (e[0] != 0xE5 && (e[11] & 0x08) == 0 && memcmp(e, name83, 11) == 0) found = 1;
                }
                if (found) { memcpy(entry_out, e, 32); *sec_out = sec + s; *off_out = o; break; }
            }
        }
        if (found) break;
        if (d->is_fixed_root) break;
        uint32_t n = fat_get(c);
        if (is_eoc(n)) {
            if (!want_free) break;
            n = alloc_cluster(); fat_set(c, n);     /* the directory grows a cluster */
        }
        c = n;
    }
    free(buf);
    return found;
}
static void entry_write(uint32_t sec, int off, const uint8_t *entry)
{
    uint8_t *buf = malloc(bps);
    read_sectors(sec, 1, buf); memcpy(buf + off, entry, 32); write_sectors(sec, 1, buf); free(buf);
}
static void now_stamp(uint8_t *e)
{
    time_t t = time(NULL); struct tm *m = localtime(&t);
    uint16_t dt = ((m->tm_year - 80) << 9) | ((m->tm_mon + 1) << 5) | m->tm_mday;
    uint16_t tm = (m->tm_hour << 11) | (m->tm_min << 5) | (m->tm_sec / 2);
    wr16(e + 14, tm); wr16(e + 16, dt); wr16(e + 18, dt); wr16(e + 22, tm); wr16(e + 24, dt);
}
static void entry_set_cluster(uint8_t *e, uint32_t c) { wr16(e + 26, c & 0xFFFF); wr16(e + 20, fat_type == 32 ? c >> 16 : 0); }
static uint32_t entry_cluster(const uint8_t *e) { return rd16(e + 26) | (fat_type == 32 ? (uint32_t)rd16(e + 20) << 16 : 0); }

/* NAME.EXT -> 11 characters (capitals, spaces); 0 when it isn't 8.3 */
static int name83(const char *s, char *out)
{
    const char *dot = strrchr(s, '.');
    int nl = dot ? (int)(dot - s) : (int)strlen(s), xl = dot ? (int)strlen(dot + 1) : 0;
    if (nl < 1 || nl > 8 || xl > 3) return 0;
    memset(out, ' ', 11);
    for (int i = 0; i < nl; i++) { char c = toupper((unsigned char)s[i]); if (c <= ' ' || strchr("\"*+,/:;<=>?[\\]|.", c)) return 0; out[i] = c; }
    for (int i = 0; i < xl; i++) { char c = toupper((unsigned char)dot[1 + i]); if (c <= ' ' || strchr("\"*+,/:;<=>?[\\]|.", c)) return 0; out[8 + i] = c; }
    return 1;
}

/* the folder NAME in d: made if not there; d_out = it */
static void dir_child(dir_t *d, const char *name, dir_t *d_out)
{
    char n83[11]; uint8_t e[32]; uint32_t sec; int off;
    if (!name83(name, n83)) { fprintf(stderr, "sdinstall: %s: not an 8.3 name\n", name); exit(1); }
    if (folder_mode) {
        snprintf(d_out->path, sizeof d_out->path, "%.1000s/%.12s", d->path, name);
        if (mkdir(d_out->path, 0777) && errno != EEXIST) { perror(d_out->path); exit(1); }
        return;
    }
    if (dir_find_slot_or_entry(d, n83, e, &sec, &off, 0)) {
        if (!(e[11] & 0x10)) { fprintf(stderr, "sdinstall: %s: a file, not a folder\n", name); exit(1); }
        d_out->first_cluster = entry_cluster(e); d_out->is_fixed_root = 0; return;
    }
    uint32_t c = alloc_cluster();
    memset(e, 0, 32); memcpy(e, n83, 11); e[11] = 0x10; entry_set_cluster(e, c); now_stamp(e);
    if (!dir_find_slot_or_entry(d, n83, e + 0, &sec, &off, 1)) die("no room in the directory");
    memset(e, 0, 32); memcpy(e, n83, 11); e[11] = 0x10; entry_set_cluster(e, c); now_stamp(e);
    entry_write(sec, off, e);
    /* . and .. */
    uint8_t *buf = calloc(spc, bps);
    memset(buf, ' ', 11); buf[0] = '.'; buf[11] = 0x10; entry_set_cluster(buf, c); now_stamp(buf);
    memset(buf + 32, ' ', 11); buf[32] = '.'; buf[33] = '.'; buf[43] = 0x10;
    entry_set_cluster(buf + 32, d->is_fixed_root || (fat_type == 32 && d->first_cluster == root_cluster) ? 0 : d->first_cluster); now_stamp(buf + 32);
    write_sectors(cluster_sector(c), spc, buf); free(buf);
    d_out->first_cluster = c; d_out->is_fixed_root = 0;
}

/* the bytes at data (len) into d as NAME (over one there) */
static void put_data(dir_t *d, const char *name, const uint8_t *data, long len)
{
    char n83[11]; uint8_t e[32]; uint32_t sec; int off;
    if (!name83(name, n83)) { fprintf(stderr, "sdinstall: %s: not an 8.3 name\n", name); exit(1); }
    if (folder_mode) {
        char path[1100]; snprintf(path, sizeof path, "%s/%s", d->path, name);
        FILE *f = fopen(path, "wb"); if (!f || (len && fwrite(data, 1, len, f) != (size_t)len)) { perror(path); exit(1); }
        fclose(f); printf("  %-12s %7ld\n", name, len); return;
    }
    int had = dir_find_slot_or_entry(d, n83, e, &sec, &off, 0);
    if (had) { if (e[11] & 0x10) { fprintf(stderr, "sdinstall: %s: a folder is there\n", name); exit(1); } free_chain(entry_cluster(e)); }
    else { if (!dir_find_slot_or_entry(d, n83, e, &sec, &off, 1)) die("no room in the directory"); memset(e, 0, 32); memcpy(e, n83, 11); e[11] = 0x20; }
    uint32_t first = 0, prev = 0, csize = spc * bps;
    for (long at = 0; at < len; at += csize) {
        uint32_t c = alloc_cluster();
        if (prev) fat_set(prev, c); else first = c;
        uint8_t *buf = calloc(spc, bps); memcpy(buf, data + at, len - at < csize ? len - at : csize);
        write_sectors(cluster_sector(c), spc, buf); free(buf); prev = c;
    }
    entry_set_cluster(e, first); wr32(e + 28, (uint32_t)len); now_stamp(e); e[11] = 0x20;
    entry_write(sec, off, e);
    printf("  %-12s %7ld\n", name, len);
}
/* the file at path into d as NAME */
static void put_file(dir_t *d, const char *path, const char *name)
{
    FILE *f = fopen(path, "rb"); if (!f) { perror(path); exit(1); }
    fseek(f, 0, SEEK_END); long len = ftell(f); fseek(f, 0, SEEK_SET);
    uint8_t *data = malloc(len ? len : 1); if (len && fread(data, 1, len, f) != (size_t)len) die("read failed"); fclose(f);
    put_data(d, name, data, len); free(data);
}

/* ---- the CPC's discs: CPCEMU .DSK (standard or extended), AMSDOS data format - 40 tracks of 9
 * sectors #C1-#C9 of 512 bytes, 1K blocks from track 0, the directory the first 4 sectors (64
 * entries of 32: user, name 8 + 3, extent, -, -, records, 16 blocks) */
typedef struct { uint8_t *d; long size; int tracks; int tsize; int ext; } dsk_t;
static const uint8_t *dsk_sector(dsk_t *k, int t, int id)
{
    if (t >= k->tracks) return NULL;
    long base = 256;
    if (k->ext) { for (int i = 0; i < t; i++) base += (long)k->d[52 + i] * 256; }
    else base += (long)t * k->tsize;
    if (base + 256 > k->size) return NULL;
    const uint8_t *ti = k->d + base; int n = ti[21]; long off = base + 256;
    for (int i = 0; i < n; i++) {
        const uint8_t *info = ti + 24 + 8 * i; int ssz = k->ext ? rd16(info + 6) : 128 << info[3];
        if (info[2] == id) return (off + 512 <= k->size) ? k->d + off : NULL;
        off += ssz;
    }
    return NULL;
}
static const uint8_t *dsk_block_half(dsk_t *k, int b, int half)
{
    int i = b * 2 + half; return dsk_sector(k, i / 9, 0xC1 + i % 9);
}
static dsk_t *dsk_open(const char *path)
{
    FILE *f = fopen(path, "rb"); if (!f) { perror(path); exit(1); }
    dsk_t *k = calloc(1, sizeof *k);
    fseek(f, 0, SEEK_END); k->size = ftell(f); fseek(f, 0, SEEK_SET);
    k->d = malloc(k->size); if (fread(k->d, 1, k->size, f) != (size_t)k->size) die("read failed"); fclose(f);
    if (k->size < 256 || (memcmp(k->d, "MV - CPC", 8) && memcmp(k->d, "EXTENDED", 8))) { fprintf(stderr, "sdinstall: %s: not a CPCEMU .DSK\n", path); exit(1); }
    k->ext = !memcmp(k->d, "EXTENDED", 8); k->tracks = k->d[48]; k->tsize = rd16(k->d + 50);
    return k;
}
/* the file NAME (8.3) on the disc: its bytes (malloc), *len; NULL when it isn't there */
static uint8_t *dsk_file(dsk_t *k, const char *name, long *len)
{
    char n83[11]; if (!name83(name, n83)) return NULL;
    uint8_t *out = NULL; long total = 0; int found = 0;
    for (int ex = 0; ex < 32; ex++) {                 /* its extents in order */
        int got = 0;
        for (int i = 0; i < 64 && !got; i++) {
            const uint8_t *s = dsk_sector(k, 0, 0xC1 + i / 16); if (!s) break;
            const uint8_t *e = s + (i % 16) * 32;
            if (e[0] != 0) continue;
            char en[11]; for (int j = 0; j < 11; j++) en[j] = e[1 + j] & 0x7F;
            if (memcmp(en, n83, 11) || e[12] != ex) continue;
            int rc = e[15]; got = 1; found = 1;
            out = realloc(out, total + rc * 128 + 1);
            for (int b = 0; b < 16 && rc > 0; b++) {
                if (!e[16 + b]) break;
                for (int h = 0; h < 2 && rc > 0; h++) {
                    const uint8_t *sec = dsk_block_half(k, e[16 + b], h); if (!sec) die("a block off the disc");
                    int n = rc < 4 ? rc : 4; memcpy(out + total, sec, n * 128); total += n * 128; rc -= n;
                }
            }
        }
        if (!got) break;
    }
    if (!found) return NULL;
    *len = total; return out;
}
/* INSTALL.BAS's DATA list from disc 1: the quoted strings from "#1" to "*" (DATA keeps its text as
 * typed in a tokenised Locomotive BASIC file) - n strings, each a path under CYBORGOS/ or "#n" */
static int install_list(dsk_t *disc1, char ***list_out)
{
    long len; uint8_t *b = dsk_file(disc1, "INSTALL.BAS", &len);
    if (!b) die("INSTALL.BAS isn't on the first disc (cos-disk1)");
    char **list = NULL; int n = 0, started = 0;
    for (long i = 0; i < len; i++) {
        if (b[i] != '"') continue;
        long j = i + 1; while (j < len && b[j] != '"' && b[j] >= ' ') j++;
        if (j >= len || b[j] != '"') { i = j; continue; }
        char *s = strndup((char *)b + i + 1, j - i - 1); i = j;
        if (!started) { if (!strcmp(s, "#1")) started = 1; else { free(s); continue; } }
        if (!strcmp(s, "*")) { free(s); break; }
        list = realloc(list, (n + 1) * sizeof *list); list[n++] = s;
    }
    free(b);
    if (!started) die("INSTALL.BAS: no DATA list (\"#1\" ... \"*\")");
    *list_out = list; return n;
}
static void install_discs(dir_t *root, char **dsks, int ndsk)
{
    dsk_t *disc1 = dsk_open(dsks[0]); char **list; int n = install_list(disc1, &list);
    dsk_t *cur = disc1; int curno = 1, copied = 0, skipped = 0;
    for (int i = 0; i < n; i++) {
        const char *s = list[i];
        if (s[0] == '#') {
            curno = atoi(s + 1); cur = NULL;
            for (int k = 0; k < ndsk; k++) {        /* the disc named cos-diskN, or the Nth given */
                char tag[16]; snprintf(tag, sizeof tag, "disk%d", curno);
                if (strstr(dsks[k], tag)) { cur = (k == 0) ? disc1 : dsk_open(dsks[k]); break; }
            }
            if (!cur && curno - 1 < ndsk && !strstr(dsks[curno - 1], "disk")) cur = (curno == 1) ? disc1 : dsk_open(dsks[curno - 1]);
            printf(" disc %d: %s\n", curno, cur ? "" : "not given - its files skipped");
            continue;
        }
        if (!cur) { skipped++; continue; }
        const char *name = strrchr(s, '/'); name = name ? name + 1 : s;
        long len; uint8_t *data = dsk_file(cur, name, &len);
        if (!data) { printf("  %s: not on disc %d\n", name, curno); skipped++; continue; }
        dir_t d = *root; char *p = strdup(s), *tok = strtok(p, "/");
        while (tok && strcmp(tok, name)) { dir_t sub; dir_child(&d, tok, &sub); d = sub; tok = strtok(NULL, "/"); }
        put_data(&d, name, data, len); free(data); free(p); copied++;
    }
    printf("%d files copied, %d skipped\n", copied, skipped);
}

static void copy_tree(dir_t *d, const char *src)
{
    DIR *dp = opendir(src); if (!dp) { perror(src); exit(1); }
    struct dirent *de; char path[4096]; struct stat st;
    /* files first, then folders (the listing reads as INSTALL.BAS's) */
    for (int pass = 0; pass < 2; pass++) {
        rewinddir(dp);
        while ((de = readdir(dp))) {
            if (de->d_name[0] == '.') continue;
            snprintf(path, sizeof path, "%s/%s", src, de->d_name);
            if (stat(path, &st)) continue;
            if (pass == 0 && S_ISREG(st.st_mode)) put_file(d, path, de->d_name);
            if (pass == 1 && S_ISDIR(st.st_mode)) { dir_t sub; printf(" %s/\n", de->d_name); dir_child(d, de->d_name, &sub); copy_tree(&sub, path); }
        }
    }
    closedir(dp);
}

/* ---- --new IMAGE MB: a blank image - an MBR with one FAT32 partition from sector 2048 (as a card
 * formatted by a camera or a PC: what NextZXOS, UniDOS and WinAPE read), 8 sectors a cluster,
 * two FATs, the root at cluster 2, FSInfo and the backup boot sector in place. 33MB to 2GB */
static void new_image(const char *path, long mb)
{
    if (mb < 33 || mb > 2048) die("--new: 33 to 2048 MB");
    uint32_t total = (uint32_t)mb * 2048, start = 2048, n = total - start, cl = 8, res = 32, nfats = 2;
    uint32_t fatsz = (n - res + 2 * cl) / (cl * 128 + nfats);     /* FAT sectors: enough for every cluster (128 entries a sector) */
    uint32_t clusters = (n - res - nfats * fatsz) / cl;
    if (clusters < 65525) die("--new: too small for FAT32 (33MB or more)");
    FILE *f = fopen(path, "wb"); if (!f) { perror(path); exit(1); }
    uint8_t *sec = calloc(512, 1);
    /* the MBR */
    sec[446 + 4] = 0x0C; wr32(sec + 446 + 8, start); wr32(sec + 446 + 12, n); sec[510] = 0x55; sec[511] = 0xAA;
    fwrite(sec, 512, 1, f); memset(sec, 0, 512);
    /* the boot sector (BPB) */
    uint8_t *bs = calloc(512, 1);
    bs[0] = 0xEB; bs[1] = 0x58; bs[2] = 0x90; memcpy(bs + 3, "MSWIN4.1", 8);
    wr16(bs + 11, 512); bs[13] = cl; wr16(bs + 14, res); bs[16] = nfats; wr16(bs + 17, 0); wr16(bs + 19, 0); bs[21] = 0xF8;
    wr16(bs + 22, 0); wr16(bs + 24, 63); wr16(bs + 26, 255); wr32(bs + 28, start); wr32(bs + 32, n);
    wr32(bs + 36, fatsz); wr16(bs + 40, 0); wr16(bs + 42, 0); wr32(bs + 44, 2); wr16(bs + 48, 1); wr16(bs + 50, 6);
    bs[64] = 0x80; bs[66] = 0x29; wr32(bs + 67, (uint32_t)time(NULL)); memcpy(bs + 71, "CYBORGOS   ", 11); memcpy(bs + 82, "FAT32   ", 8);
    bs[510] = 0x55; bs[511] = 0xAA;
    /* FSInfo */
    uint8_t *fi = calloc(512, 1);
    wr32(fi, 0x41615252); wr32(fi + 484, 0x61417272); wr32(fi + 488, clusters - 1); wr32(fi + 492, 3); fi[510] = 0x55; fi[511] = 0xAA;
    if (fseeko(f, (off_t)start * 512, SEEK_SET)) die("seek");
    fwrite(bs, 512, 1, f); fwrite(fi, 512, 1, f);
    if (fseeko(f, (off_t)(start + 6) * 512, SEEK_SET)) die("seek");
    fwrite(bs, 512, 1, f); fwrite(fi, 512, 1, f);               /* the backup copies at 6, 7 */
    /* the FATs: media, end of chain, the root's cluster */
    memset(sec, 0, 512); wr32(sec, 0x0FFFFFF8); wr32(sec + 4, 0x0FFFFFFF); wr32(sec + 8, 0x0FFFFFFF);
    for (uint32_t i = 0; i < nfats; i++) { if (fseeko(f, (off_t)(start + res + i * fatsz) * 512, SEEK_SET)) die("seek"); fwrite(sec, 512, 1, f); }
    /* the root directory: one empty cluster; the volume label in it */
    memset(sec, 0, 512); memcpy(sec, "CYBORGOS   ", 11); sec[11] = 0x08;
    if (fseeko(f, (off_t)(start + res + nfats * fatsz) * 512, SEEK_SET)) die("seek");
    fwrite(sec, 512, 1, f);
    if (fseeko(f, (off_t)total * 512 - 1, SEEK_SET)) die("seek");
    fputc(0, f);                                                 /* the full size */
    fclose(f); free(sec); free(bs); free(fi);
    printf("%s: %ldMB, FAT32, %u clusters of 4K\n", path, mb, clusters);
}

int main(int argc, char **argv)
{
    if (argc < 3) { fprintf(stderr, "sdinstall IMAGE SRCDIR [/DEST/PATH]\nsdinstall IMAGE --dsk cos-disk1.dsk cos-disk2.dsk ... [/DEST/PATH]   (the default /CYBORGOS)\nsdinstall --new IMAGE MB   (a blank image: an MBR, one FAT32 partition)\n"); return 1; }
    if (!strcmp(argv[1], "--new")) { if (argc < 4) die("--new IMAGE MB"); new_image(argv[2], atol(argv[3])); return 0; }
    const char *dest = "/CYBORGOS"; int dsk_mode = !strcmp(argv[2], "--dsk"), ndsk = 0;
    char **dsks = argv + 3;
    if (dsk_mode) {                              /* the discs: the .dsk files; then the destination */
        while (3 + ndsk < argc) { const char *a = argv[3 + ndsk]; size_t l = strlen(a); if (l < 4 || strcasecmp(a + l - 4, ".dsk")) break; ndsk++; }
        if (!ndsk) die("--dsk: the discs (.dsk files)");
        if (3 + ndsk < argc) dest = argv[3 + ndsk];
    }
    else if (argc > 3) dest = argv[3];
    struct stat st_img;
    if (!stat(argv[1], &st_img) && S_ISDIR(st_img.st_mode)) {    /* a folder, not an image: the files as they are */
        folder_mode = 1; dir_t d; memset(&d, 0, sizeof d);
        snprintf(d.path, sizeof d.path, "%s", argv[1]);
        char *p = strdup(dest), *tok = strtok(p, "/");
        while (tok) { dir_t sub; dir_child(&d, tok, &sub); d = sub; tok = strtok(NULL, "/"); }
        printf("into %s%s:\n", argv[1], dest);
        if (dsk_mode) install_discs(&d, dsks, ndsk); else copy_tree(&d, argv[2]);
        return 0;
    }
    img = fopen(argv[1], "r+b"); if (!img) { perror(argv[1]); return 1; }
    uint8_t s0[512];
    bps = 512; part_lba = 0;
    if (fread(s0, 1, 512, img) != 512) die("not an image");
    if (!memcmp(s0, "BITWISE DRIVE IMAGE FILE", 24)) {     /* WinAPE's IDE image: through its block map */
        sparse = 1; fseeko(img, 0, SEEK_END); file_blocks = (uint32_t)(ftello(img) / 512);
        read_sectors(0, 1, s0);
        printf("%s: WinAPE IDE image (%u blocks in the file)\n", argv[1], file_blocks);
    }
    if (!(s0[0] == 0xEB || s0[0] == 0xE9) || rd16(s0 + 11) == 0 || (rd16(s0 + 11) & (rd16(s0 + 11) - 1))) {
        /* not a boot sector: an MBR - partition 1 */
        if (s0[510] != 0x55 || s0[511] != 0xAA || s0[0x1C2] == 0) die("neither a FAT boot sector nor an MBR with a partition");
        part_lba = rd32(s0 + 0x1C6);
        read_sectors(0, 1, s0);
    }
    bps = rd16(s0 + 11); spc = s0[13]; reserved = rd16(s0 + 14); nfats = s0[16]; root_entries = rd16(s0 + 17);
    total_sectors = rd16(s0 + 19) ? rd16(s0 + 19) : rd32(s0 + 32);
    fat_sectors = rd16(s0 + 22) ? rd16(s0 + 22) : rd32(s0 + 36);
    if (!bps || !spc || !nfats || !fat_sectors) die("not a FAT volume");
    fat_start = reserved; root_start = fat_start + nfats * fat_sectors;
    uint32_t root_sectors = (root_entries * 32 + bps - 1) / bps;
    data_start = root_start + root_sectors;
    clusters = (total_sectors - data_start) / spc;
    fat_type = clusters < 4085 ? 12 : clusters < 65525 ? 16 : 32;
    eoc = fat_type == 32 ? 0x0FFFFFFF : fat_type == 16 ? 0xFFFF : 0xFFF;
    root_cluster = fat_type == 32 ? rd32(s0 + 44) : 0;
    fsinfo_sector = fat_type == 32 ? rd16(s0 + 48) : 0;
    printf("%s: FAT%d, %u clusters of %u bytes%s\n", argv[1], fat_type, clusters, spc * bps, part_lba ? " (partition 1)" : "");
    fat = malloc((size_t)fat_sectors * bps); read_sectors(fat_start, fat_sectors, fat);
    if (fat_type == 32 && fsinfo_sector) {   /* a hint of where free clusters start */
        uint8_t *fi = malloc(bps); read_sectors(fsinfo_sector, 1, fi);
        if (rd32(fi) == 0x41615252 && rd32(fi + 492) >= 2 && rd32(fi + 492) < clusters + 2) next_free = rd32(fi + 492);
        free(fi);
    }
    dir_t d; d.first_cluster = root_cluster; d.is_fixed_root = (fat_type != 32);
    char *p = strdup(dest), *tok = strtok(p, "/");
    while (tok) { dir_t sub; dir_child(&d, tok, &sub); d = sub; tok = strtok(NULL, "/"); }
    printf("into %s:\n", dest);
    if (dsk_mode) install_discs(&d, dsks, ndsk); else copy_tree(&d, argv[2]);
    for (int i = 0; i < nfats; i++) write_sectors(fat_start + i * fat_sectors, fat_sectors, fat);
    if (fat_type == 32 && fsinfo_sector) {   /* the free count isn't kept: unknown */
        uint8_t *fi = malloc(bps); read_sectors(fsinfo_sector, 1, fi);
        if (rd32(fi) == 0x41615252) { wr32(fi + 488, 0xFFFFFFFF); wr32(fi + 492, next_free); write_sectors(fsinfo_sector, 1, fi); }
        free(fi);
    }
    fclose(img);
    printf("done\n");
    return 0;
}
