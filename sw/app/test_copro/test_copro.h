#include <stdint.h>

#ifndef COPROC_H
#define COPROC_H

#define BULK_SQUARE 0
#define BULK_SCALE 1

typedef struct {
    int16_t r;
    int16_t i;
} complex16_t;

int32_t pack(complex16_t c)
{
    return ((int32_t)c.r << 16) | ((uint16_t)c.i);
}

static inline int16_t coproc_add(int16_t a, int16_t b)
{
    int result;

    asm volatile(
        ".insn r 0x7B, 1, 0, %0, %1, %2"
        : "=r"(result)   // rd
        : "r"(a), "r"(b) // rs1, rs2
    );

    return result;
}

static inline void coproc_push(int16_t val_r, int16_t val_i)
{
    asm volatile(
        ".insn r 0x7B, 2, 0, x0, %0, %1"
        :
        : "r"(val_r), "r"(val_i)
        : "memory");
}

static inline void coproc_bulk_compute(uint16_t bulk_op)
{
    asm volatile(
        ".insn r 0x7B, 3, 0, x0, %0, x0"
        :
        : "r"(bulk_op)
        : "memory");
}

static inline complex16_t coproc_read(uint16_t index)
{
    int32_t out;
    complex16_t out2;
    
    asm volatile(
        ".insn r 0x7B, 4, 0, %0, %1, x0"
        : "=r"(out)
        : "r"(index));
    out2.r = (int16_t)(out >> 16);
    out2.i = (int16_t)(out & 0xFFFF);
    return out2;
}

static inline int32_t coproc_status(void)
{
    int32_t s;
    asm volatile(
        ".insn r 0x7B, 5, 0, %0, x0, x0"
        : "=r"(s));
    return s;
}

static inline void coproc_scale_one(uint16_t index, int32_t coeff)
{
    asm volatile(
        ".insn r 0x7B, 6, 0, x0, %0, %1"
        :
        : "r"(index), "r"(coeff)
        : "memory");
}

#endif
