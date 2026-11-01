// emu.h - a stand-in for the parts of MAME's framework that sound/votrax.cpp uses, so the chip's
// code compiles unchanged: a device base, a sound stream, a timer in clock ticks, the internal
// ROM from a file. The emulation itself is MAME's (BSD-3-Clause, Olivier Galibert); this shim
// and main.cpp are CyborgOS's (MIT). No save states, no logging.
#pragma once
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <string>
#include <vector>
#include <functional>

typedef uint8_t u8; typedef uint16_t u16; typedef uint32_t u32; typedef uint64_t u64;
typedef int8_t s8; typedef int16_t s16; typedef int32_t s32; typedef int64_t s64;

#define LOGMASKED(...) do {} while (0)
#define LOG(...) do {} while (0)
#define NAME(x) x, #x
#define FUNC(x) &x
#define ASSERT_LINE 1
#define CLEAR_LINE 0
#define TIMER_CALLBACK_MEMBER(name) void name(s32 param)
#define DEFINE_DEVICE_TYPE(type, cls, shortname, fullname) const device_type type = shortname;
#define DECLARE_DEVICE_TYPE(type, cls) extern const device_type type;
#define ROM_START(name) static const tiny_rom_entry rom_##name[] = {
#define ROM_REGION64_LE(a, b, c) {},
#define ROM_LOAD(a, b, c, d) {},
#define ROM_END {} };
#define ROM_NAME(name) rom_##name
#define CRC(x) 0
#define SHA1(x) 0
#define CHECK_SPEC  //
#define M_PI_SHIM 3.14159265358979323846

typedef const char *device_type;
struct machine_config {};
struct tiny_rom_entry { int dummy; };

// time in ticks of a clock: the device's main clock is the unit kept here
struct attotime
{
	double seconds;
	bool never;
	attotime() : seconds(0), never(true) {}
	explicit attotime(double s_a) : seconds(s_a), never(false) {}
	static attotime from_ticks(u64 ticks_a, u32 clock_a) { return attotime(double(ticks_a) / double(clock_a)); }
	static attotime never_() { return attotime(); }
	bool is_never() const { return never; }
	u64 as_ticks(u32 clock_a) const { return never ? 0 : u64(seconds * clock_a + 0.5); }
	attotime operator-(const attotime &o_a) const { return attotime(seconds - o_a.seconds); }
};

struct emu_timer;
struct device_t;
struct running_machine
{
	double now;
	running_machine() : now(0) {}
	attotime time() const { return attotime(now); }
};

struct emu_timer
{
	std::function<void(s32)> fn;
	attotime at;		// when it fires (absolute), never when idle
	s32 prm;
	running_machine *m;
	emu_timer() : prm(0), m(nullptr) {}
	void adjust(attotime delay_a, s32 param_a = 0) { at = attotime(m->now + delay_a.seconds); prm = param_a; }
	attotime expire() const { return at; }
	s32 param() const { return prm; }
	attotime remaining() const { return at.is_never() ? attotime() : attotime(at.seconds - m->now); }
};

struct sound_stream
{
	typedef float sample_t;
	std::vector<float> out;
	int n;
	sound_stream() : n(0) {}
	int samples() const { return n; }
	void put(int, int i_a, double v_a) { out[i_a] = float(v_a); }
	void update() {}
	void set_sample_rate(u32) {}
};

struct device_t
{
	running_machine mach;
	u32 clk;
	emu_timer tmr;
	sound_stream strm;
	device_t(const machine_config &, device_type, const char *, device_t *, u32 clock_a) : clk(clock_a) { tmr.m = &mach; }
	virtual ~device_t() {}
	u32 clock() const { return clk; }
	running_machine &machine() { return mach; }
	emu_timer *timer_alloc(void (*)(), void *) { return &tmr; }	// (not used: the template below is)
	template<class F, class C> emu_timer *timer_alloc(F f_a, C *c_a) { tmr.fn = [=](s32 p_a) { (c_a->*f_a)(p_a); }; return &tmr; }
	sound_stream *stream_alloc(int, int, u32) { return &strm; }
	template<class T> void save_item(T &, const char *) {}
	template<class T> void save_item(T *, const char *) {}
	virtual void device_start() {}
	virtual void device_reset() {}
	virtual void device_clock_changed() {}
	virtual const tiny_rom_entry *device_rom_region() const { return nullptr; }
	virtual void sound_stream_update(sound_stream &) {}
};
#define ATTR_COLD
struct device_sound_interface { device_sound_interface(const machine_config &, device_t &) {} };

struct devcb_write_line
{
	devcb_write_line(device_t &) {}
	void operator()(int) {}
	template<class T> void set(T) {}
	devcb_write_line &bind() { return *this; }
};

// the internal ROM: a file given to the program (m_rom->base())
struct memory_region
{
	std::vector<u8> data;
	const u8 *base() const { return data.data(); }
};
struct required_memory_region
{
	memory_region reg;
	required_memory_region(device_t &, const char *) {}
	memory_region *operator->() { return &reg; }
};

// MAME's bitswap: the bits of val picked in the order given (B0 is the most significant of the result)
template<typename T, typename... U> constexpr T bitswap(T val_a, U... b_a)
{
	T r = 0; unsigned pos[] = { static_cast<unsigned>(b_a)... }; unsigned n = sizeof...(b_a);
	for (unsigned i = 0; i < n; i++) { r = (r << 1) | ((val_a >> pos[i]) & 1); }
	return r;
}
