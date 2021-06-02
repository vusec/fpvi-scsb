#ifndef FLUSH_RELOAD_H
#define FLUSH_RELOAD_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <ctype.h>

#define THRESHOLD 160
#define STRIDE	  2048
#define SERIALIZE asm volatile("dsb sy\nisb\n")

static inline __attribute__((always_inline)) void clflush(void *address)
{
    asm volatile ("dc civac, %0" :: "r"(address));
    asm volatile ("dsb ish");
    asm volatile ("isb");
}

static inline __attribute__((always_inline)) uint64_t rdtscp(void)
{
    uint64_t result = 0;
    asm volatile("mrs %0, pmccntr_el0" : "=r" (result));
    return result;
}

static inline __attribute__((always_inline)) void maccess(void *pointer)
{
    volatile uint32_t value;
    asm volatile ("ldr %0, [%1]\n\t"
            : "=r" (value)
            : "r" (pointer)
            );
}

static inline __attribute__((always_inline)) void flush(unsigned char *reloadbuffer) {
    for (size_t k = 0; k < 256; ++k) {
        clflush(reloadbuffer + k * STRIDE);
    }
    SERIALIZE;
}

static inline __attribute__((always_inline)) void reload(unsigned char *reloadbuffer, size_t *results) {
    SERIALIZE;
    for (size_t k = 0; k < 256; ++k) {
        size_t x = ((k * 167) + 13) & (0xff);

        unsigned char *p = reloadbuffer + (STRIDE * x);

        uint64_t t0 = rdtscp();
        SERIALIZE;
        maccess(p);
        SERIALIZE;
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
            printf("\t%08zu: %02x (%c)\n", results[c], (unsigned int)c,
                    isprint(c) ? (unsigned int)c : '?');
        }
    }
}

#endif
