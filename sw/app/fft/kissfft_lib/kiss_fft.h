/*
 *  Copyright (c) 2003-2010, Mark Borgerding. All rights reserved.
 *  This file is part of KISS FFT - https://github.com/mborgerding/kissfft
 *
 *  SPDX-License-Identifier: BSD-3-Clause
 *  See COPYING file for more information.
 */

#ifndef KISS_FFT_H
#define KISS_FFT_H

#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <math.h>
#include <string.h>
#include <stdint.h>

// Define KISS_FFT_SHARED macro to properly export symbols
#define KISS_FFT_API

#ifdef __cplusplus
extern "C"
{
#endif

   /*
    ATTENTION!
    If you would like a :
    -- a utility that will handle the caching of fft objects
    -- real-only (no imaginary time component ) FFT
    -- a multi-dimensional FFT
    -- a command-line utility to perform ffts
    -- a command-line utility to perform fast-convolution filtering

    Then see kfc.h kiss_fftr.h kiss_fftnd.h fftutil.c kiss_fastfir.c
     in the tools/ directory.
   */

   /* User may override KISS_FFT_MALLOC and/or KISS_FFT_FREE. */

#define KISS_FFT_ALIGN_CHECK(ptr)
#define KISS_FFT_ALIGN_SIZE_UP(size) (size)
#ifndef KISS_FFT_MALLOC
#define KISS_FFT_MALLOC malloc
#endif
#ifndef KISS_FFT_FREE
#define KISS_FFT_FREE free
#endif

   struct kiss_fft_state
   {
      int nfft;
      int inverse;

      // THE C_EXP OPERATIONS ARE PRECALCULATED
      int *factors;
      int32_t *twiddles;
   };

   typedef struct kiss_fft_state *kiss_fft_cfg;

   /*
    *  kiss_fft_alloc
    *
    *  Initialize a FFT (or IFFT) algorithm's cfg/state buffer.
    *
    *  typical usage:      kiss_fft_cfg mycfg=kiss_fft_alloc(1024,0,NULL,NULL);
    *
    *  The return value from fft_alloc is a cfg buffer used internally
    *  by the fft routine or NULL.
    *
    *  If lenmem is NULL, then kiss_fft_alloc will allocate a cfg buffer using malloc.
    *  The returned value should be free()d when done to avoid memory leaks.
    *
    *  The state can be placed in a user supplied buffer 'mem':
    *  If lenmem is not NULL and mem is not NULL and *lenmem is large enough,
    *      then the function places the cfg in mem and the size used in *lenmem
    *      and returns mem.
    *
    *  If lenmem is not NULL and ( mem is NULL or *lenmem is not large enough),
    *      then the function returns NULL and places the minimum cfg
    *      buffer size in *lenmem.
    * */

   kiss_fft_cfg KISS_FFT_API kiss_fft_alloc(int nfft, int inverse_fft, void *mem, size_t *lenmem);

   /*
    * kiss_fft(cfg,in_out_buf)
    *
    * Perform an FFT on a complex input buffer.
    * for a forward FFT,
    * fin should be  f[0] , f[1] , ... ,f[nfft-1]
    * fout will be   F[0] , F[1] , ... ,F[nfft-1]
    * Note that each element is complex and can be accessed like
       f[k].r and f[k].i
    * */
   void KISS_FFT_API kiss_fft(kiss_fft_cfg cfg, const int32_t *fin, int32_t *fout);

   /*
    A more generic version of the above function. It reads its input from every Nth sample.
    * */
   void KISS_FFT_API kiss_fft_stride(kiss_fft_cfg cfg, const int32_t *fin, int32_t *fout, int fin_stride);

/* If kiss_fft_alloc allocated a buffer, it is one contiguous
   buffer and can be simply free()d when no longer needed*/
#define kiss_fft_free KISS_FFT_FREE

#ifdef __cplusplus
}
#endif

#endif
