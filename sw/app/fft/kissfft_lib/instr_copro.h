#include <stdint.h>

#ifndef COPROC_H
#define COPROC_H

/*int32_t pack(kiss_fft_cpx c)
{
    return ((int32_t)c.r << 16) | ((uint16_t)c.i);
}*/

int16_t unpack_r(int32_t c)
{
    return (int16_t)(c>>16);
}
int16_t unpack_i(int32_t c)
{
    return (int16_t)((c<<16)>>16);
}

static inline int32_t coproc_radix_c(int32_t a, int32_t b)
{
    int32_t out;

    asm volatile(
        ".insn r 0x7B, 0, 1, %0, %1, %2"
        : "=r"(out)      // rd
        : "r"(a), "r"(b) // rs1, rs2
    );
    return out;
}

static inline int32_t coproc_radix_r(void)
{
    int32_t out;

    asm volatile(
        ".insn r 0x7B, 1, 1, %0, x0, x0"
        : "=r"(out));
    return out;
}

static inline void coproc_r4_push_2in(int32_t in1, int32_t in2)
{
    asm volatile(
        ".insn r 0x7B, 0, 2, x0, %0, %1"
        :
        : "r"(in1), "r"(in2)
        : "memory");
}

static inline void coproc_r4_push_mult(int32_t in3, int32_t in4)
{
    asm volatile(
        ".insn r 0x7B, 2, 2, x0, %0, %1"
        :
        : "r"(in3), "r"(in4)
        : "memory");
}

static inline int32_t coproc_r4_push_read_1(int32_t in1)
{
    int32_t out;

    asm volatile(
        ".insn r 0x7B, 3, 2, %0, %1, x0"
        : "=r"(out) // rd
        : "r"(in1)  // rs1, rs2
    );
    return out;
}

static inline int32_t coproc_r4_push_read_2(int32_t in2, int32_t in_co2)
{
    int32_t out;

    asm volatile(
        ".insn r 0x7B, 4, 2, %0, %1, %2"
        : "=r"(out)             // rd
        : "r"(in2), "r"(in_co2) // rs1, rs2
    );
    return out;
}

static inline int32_t coproc_r4_push_read_3(int32_t in3, int32_t in_co3)
{
    int32_t out;

    asm volatile(
        ".insn r 0x7B, 5, 2, %0, %1, %2"
        : "=r"(out)             // rd
        : "r"(in3), "r"(in_co3) // rs1, rs2
    );
    return out;
}

static inline int32_t coproc_r4_push_read_4(int32_t in4, int32_t in_co4)
{
    int32_t out;

    asm volatile(
        ".insn r 0x7B, 6, 2, %0, %1, %2"
        : "=r"(out)             // rd
        : "r"(in4), "r"(in_co4) // rs1, rs2
    );
    return out;
}

#endif
