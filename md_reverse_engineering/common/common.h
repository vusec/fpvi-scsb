#define _GNU_SOURCE
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
#include <unistd.h>
#include <ctype.h>
#include <pthread.h>
#include <sched.h>
#include <cpuid.h>

#define MMAP_FLAGS (MAP_ANONYMOUS | MAP_PRIVATE | MAP_POPULATE)
#define MAX_ITERS 500000

//See st_ld.S
extern  uint64_t              st_ld(unsigned char *store_addr, unsigned char *load_addr);
extern  uint64_t pc_unaligned_st_ld(unsigned char *store_addr, unsigned char *load_addr);
extern  uint64_t   pc_aligned_st_ld(unsigned char *store_addr, unsigned char *load_addr);
extern  uint64_t               leak(unsigned char *store_addr, unsigned char *load_addr, unsigned char *reloadbuf, int st_val);
extern  uint64_t          leak_ridl(unsigned char *store_addr, unsigned char *load_addr, unsigned char *reloadbuf, uint64_t *st_val);

//Dummy memory used by the store/loads under test
unsigned char *mem;

//Number of times we call st_ld
uint32_t iter = 0;

//History of counter's results for each call of st_ld
uint64_t counters[MAX_ITERS];
    
#define ALLOC() \
mem = (unsigned char *) mmap(NULL, 10*4096, PROT_READ | PROT_WRITE, MMAP_FLAGS, -1, 0); \
memset(mem, 0x80, 10*4096); \
memset(counters, 0, sizeof(counters)); \

//Call n times ls_st with the specified store and load addresses ()
static inline __attribute__((always_inline)) void call_st_ld(int n, int store_idx, int load_idx)
{
    for(int i=0; i<n; i++)
    {
        counters[iter++] = st_ld(&mem[store_idx], &mem[load_idx]);
    } 
}

static inline __attribute__((always_inline)) void call_pc_unaligned_st_ld(int n, int store_idx, int load_idx)
{
    for(int i=0; i<n; i++)
    {
        counters[iter++] = pc_unaligned_st_ld(&mem[store_idx], &mem[load_idx]);
    } 
}

static inline __attribute__((always_inline)) void call_pc_aligned_st_ld(int n, int store_idx, int load_idx)
{
    for(int i=0; i<n; i++)
    {
        counters[iter++] = pc_aligned_st_ld(&mem[store_idx], &mem[load_idx]);
    } 
}

//Print all the counters values (used by plotter.py)
void print_counters(int n)
{
    uint32_t time;
    uint32_t c1,c2;
    uint64_t res;

    for(int i=0; i<n; i++)
    {
        res = counters[i];
        time = res & 0xffffffff;
        c2 = (res >> 32) & 0xffff;
        c1 = (res >> 48) & 0xffff;
        printf("%d;%d;%d;%d\n", i, c1, c2, time);
    }
}
