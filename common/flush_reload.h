#ifndef _FLUSH_RELOAD_H_
#define _FLUSH_RELOAD_H_

#include <ctype.h>
#include <stdint.h>

#define LEAK_MASK       (LEAK_SIZE-1)
#define HIT_THRESHOLD   160

static inline __attribute__((always_inline)) void flush(unsigned char *reloadbuffer)
{
    for (size_t k = 0; k < LEAK_SIZE; ++k)
    {
        asm volatile("clflush (%0)\n"::"r"((volatile void *)(reloadbuffer + k * STRIDE)));
    }
    asm volatile("mfence\n");                                                                           
}

static inline __attribute__((always_inline)) uint64_t rdtscp(void)
{
    uint64_t lo, hi;
    asm volatile("rdtscp\n" : "=a" (lo), "=d" (hi) :: "rcx");
    return (hi << 32) | lo;
}

static inline __attribute__((always_inline)) void maccess(unsigned char *reloadbuffer, size_t x)
{
    *(volatile unsigned char *)(reloadbuffer + x*STRIDE); 
}

static inline __attribute__((always_inline)) void reload(unsigned char *reloadbuffer, size_t *results)
{
    asm volatile("mfence\n");                                                                           
    for (size_t k = 0; k < LEAK_SIZE; ++k)
    {                                                                  
#if LEAK_SIZE == 256
        size_t x = ((k * 167) + 13) & (0xff);
#elif LEAK_SIZE == 16
        size_t x = ((k * 7) + 11) & (0xf);
#elif LEAK_SIZE == 2
        size_t x = k;
#elif LEAK_SIZE == 1024
        size_t x = ((k * 77) + 981) & (0x3ff);
#else
    #error  "Leak size not yet supported"
#endif

        unsigned char *p = reloadbuffer + (STRIDE * x);                                                   

        uint64_t t0 = rdtscp();                                                                         
        *(volatile unsigned char *)p;                                                                   
        uint64_t dt = rdtscp() - t0;                                                                    

        if (dt < HIT_THRESHOLD) results[x]++;                                                                     
    }                                                                                                   
}                                                                                                       

void print_results(size_t *results, size_t threshold)
{
    for (size_t c = 0; c < LEAK_SIZE; ++c)
    {
        if (results[c] >= threshold)
        {
            printf("\t%08zu: %02x (%c)\n", results[c], (unsigned int)c, isprint(c) ? (unsigned int)c : '?');
        }
    }
}

#endif
