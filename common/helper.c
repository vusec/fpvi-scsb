#define _GNU_SOURCE
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <getopt.h>
#include <errno.h>
#include <asm/msr.h>
#include <sched.h>
#include <cpuid.h>
#include <assert.h>
#include <sched.h>
#include <pthread.h>
#include "helper.h"

void set_cpu(int core_idx)
{
    cpu_set_t main_thread_mask;
    CPU_ZERO(&main_thread_mask);
    CPU_SET(core_idx, &main_thread_mask);
    if(sched_setaffinity(getpid(), sizeof(cpu_set_t), &main_thread_mask) == -1){
        fprintf(stderr, "Error setaffinity main thread\n");
        fflush(stdout);
        exit(EXIT_FAILURE);
    }

    assert(sched_getcpu() == core_idx);
}

pthread_t create_thread(int core_idx, void *(*target_loop) (void *), void *arg)
{
    pthread_attr_t target_thread_attrs;
    pthread_attr_init(&target_thread_attrs);
    cpu_set_t target_thread_mask;

    CPU_ZERO(&target_thread_mask);
    CPU_SET(core_idx, &target_thread_mask);

    if(pthread_attr_setaffinity_np(&target_thread_attrs, sizeof(cpu_set_t), &target_thread_mask))
    {
        printf("Error setaffinity CPUID thread\n");
        fflush(stdout);
        exit(EXIT_FAILURE);
    }

    pthread_t target_thread;
    pthread_create(&target_thread, &target_thread_attrs, target_loop, arg);

    return target_thread;
}

void cancel_thread(pthread_t tid)
{
    if (pthread_cancel(tid) != 0) {
        printf("ERROR: thread cancelation failed\n");
        exit(EXIT_FAILURE);
    }
}

int  check_tsx()
{
    if (__get_cpuid_max(0, NULL) >= 7)
    {
        unsigned a, b, c, d;
        __cpuid_count(7, 0, a, b, c, d);
        return (b & (1 << 11)) ? 1 : 0;
    }

    return 0;
}

