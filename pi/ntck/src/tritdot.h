#ifndef TRITDOT_H
#define TRITDOT_H
#include <stdint.h>
#define G_BLOCK 32
#define G_GROUP 4
#define G_LUT 81
int64_t gb_dot_scalar(const int8_t* ptrX_a, const uint8_t* const* ptrPlanes_a, int intK_a,
                      const int16_t* ptrMant_a, int intShift_a, int intIn_a);
void gb_prepare_luts(const int8_t* ptrX_a, int intIn_a, int16_t* ptrLuts_a);
int64_t gb_dot_lut(const int16_t* ptrLuts_a, const uint8_t* const* ptrPlanes_a, int intK_a,
                   const int16_t* ptrMant_a, int intShift_a, int intIn_a);
#endif
