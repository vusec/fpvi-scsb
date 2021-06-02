#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <assert.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <ctype.h>
#include "flush_reload.h"

#ifdef x86
#include <xmmintrin.h>
#include <pmmintrin.h>
#endif

#define DEBUG   0
#define ITER    1000

extern uint64_t fp_leak_trans_res(unsigned char *reloadbuf, uint64_t *x, uint64_t *y, uint64_t byte_pos);

void print_double(char *name, double n)
{
    int64_t  bias = 1023;
    uint64_t hex_n = *((uint64_t *)&n);
    uint64_t unbiased_exp = (hex_n>>52)&0x7FF;
    int64_t  biased_exp   = unbiased_exp == 0 ? -1022 : (int64_t)unbiased_exp - bias;
    uint64_t mantissa = hex_n&0x000FFFFFFFFFFFFFUL;
    
    printf("%9s = 0x%016lx    %16e    ", name, hex_n, n);
    printf("(%8s    biased_exp=%5ld    unbiased_exp=%5ld    mantissa=0x%013lx)\n",
            unbiased_exp == 0 ? "DENORMAL" : "  NORMAL",
            unbiased_exp, biased_exp, mantissa);
}

int main(int argc, char **argv)
{
    uint64_t x_hex, y_hex;
    
    //Ensure SSE default settings
    #ifdef x86
    _MM_SET_DENORMALS_ZERO_MODE(_MM_DENORMALS_ZERO_OFF);
    _MM_SET_FLUSH_ZERO_MODE(_MM_FLUSH_ZERO_OFF);
    #endif

    if (argc < 3)
    {
        fprintf(stderr, "Usage: %s <x> <y>\nEg: %s 0xc000e8b2c9755600 0x0004000000000000\n", argv[0], argv[0]);
        return -1;
    }
    sscanf(argv[1], "0x%lx", &x_hex);
    sscanf(argv[2], "0x%lx", &y_hex);

    /* Flush+Reload setup */
    __attribute__((aligned(4096))) size_t results[256] = {0};
    unsigned char *reloadbuffer = mmap(NULL, 256*STRIDE, PROT_READ | PROT_WRITE,
    #if defined(x86)
                                       MAP_ANONYMOUS | MAP_PRIVATE | MAP_POPULATE | MAP_HUGETLB, -1, 0);
    #elif defined(armv8)
                                       MAP_ANONYMOUS | MAP_PRIVATE | MAP_POPULATE, -1, 0);
    #else
    #error  "not supported arch"
    #endif
    
    /* Debug prints of input operands and arch result */
    double   x = *((double *)&x_hex);
    double   y = *((double *)&y_hex);
    //Get the FP architectural result of x/y
    uint64_t arch_res_hex = fp_leak_trans_res(reloadbuffer, &x_hex, &y_hex, 0);
    double   arch_res = *((double *) &arch_res_hex);

    print_double("x", x);
    print_double("y", y);
    print_double("arch_res", arch_res);

    /* Recover trans_res nibble by nibble
     * Leaking nibbles instead of bytes due to less noise
     */
    uint64_t trans_res_hex = 0;
    for(int i=0; i<16; i++)
    {
        memset(results, 0, sizeof(results));

        for(int j=0; j<ITER; j++)
        {
            flush(reloadbuffer);
            fp_leak_trans_res(reloadbuffer, &x_hex, &y_hex, i*4);
            reload(reloadbuffer, results);
        }

#if DEBUG == 1
        printf("Nibble %d:\n", i);
        print_results(results, ITER/10);
#endif
        //Reconstruct the speculative value
        uint8_t arch_nibble = (arch_res_hex>>i*4)&0xf;
        uint8_t spec_nibble = arch_nibble;

        //Arch result hit must be always be present, otherwise it means F+R is broken
        assert(results[arch_nibble] > ITER/10);
        for(int j=0; j<16; j++)
        {
            if(results[j] > ITER/10 && j != arch_nibble)
            {
                spec_nibble = j;    
            }
        }
        trans_res_hex |= ((uint64_t) spec_nibble) << (i*4);
    }
    
    double trans_res = *((double *)&trans_res_hex);
    print_double("trans_res", trans_res);

    return 0;
}

