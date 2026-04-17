#include "test_copro.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(void)
{
    // int16_t x = 10;
    // int16_t y = 16;

    // int16_t sum = coproc_add(x, y);

    // printf("Sum = %ld\n", sum);

    for (int16_t i = 1; i < 5; i++)
    {
        int16_t x = i*16;
        int16_t y = -i*8;
        coproc_push(x,y);
    }
    
    uint16_t reel = 0;
    uint16_t imag = 1;
    
    coproc_bulk_compute(reel);
    while (coproc_status() != 2){}
    
    coproc_bulk_compute(reel);
    while (coproc_status() != 2){}

    coproc_bulk_compute(imag);
    while (coproc_status() != 2){}
    
    complex16_t c1 = {32767, 0} ;
    
    complex16_t c2 = {16384, 32767} ;

    int32_t coef = pack(c1);
    uint16_t index = 1;
    coproc_scale_one(index, coef);
    while (coproc_status() != 2){}
    
    coef = pack(c2);
    index = 2;
    coproc_scale_one(index, coef);
    while (coproc_status() != 2){}
    

    for (int16_t i = 0; i < 4; i++)
    {
    	c1 = coproc_read(i);
    	printf("%d + i * %d\n", c1.r, c1.i);
    }

    // wait end of uart frame
    volatile int c, d;
    for (c = 1; c <= 16767; c++)
        for (d = 1; d <= 16767; d++)
        {
        }

    return (0);
}
