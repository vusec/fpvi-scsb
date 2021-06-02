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
#include <cpuid.h>
#include <signal.h>
#include <setjmp.h>
#include <xmmintrin.h>
#include <pmmintrin.h>
#include "flush_reload.h"
#include "helper.h"
    
#define EXECUTER_CORE   0
#define TRIGGER_CORE    1

/* ASM FUNCTIONS */
typedef uint64_t win_size_func_t(uint8_t *reload_buf);
extern  win_size_func_t tsx_win_size;
extern  win_size_func_t fault_win_size;
extern  win_size_func_t bht_win_size;
extern  win_size_func_t smc_win_size;
extern  win_size_func_t xmc_win_size;
extern  win_size_func_t fp_win_size;
extern  win_size_func_t fp_win_size_branch;
extern  win_size_func_t md_win_size;
extern  win_size_func_t md_win_size_branch;
extern  win_size_func_t mo_win_size;

extern  void xmc_win_size_trigger(void);
extern  void mo_win_size_trigger(void);


/* GLOBAL VARIABLES */
__attribute__((aligned(4096))) size_t results[LEAK_SIZE] = {0};
uint8_t *reload_buf;


/* PROTOTYPES */
void win_size_run(win_size_func_t win_size_func);
void thread_win_size_run(win_size_func_t win_size_func, void *(*loop) (void *));
void *xmc_trigger_loop(void *arg);
void *mo_trigger_loop(void *arg);
void fault_win_size_run();

/* MAIN */
int main(int argc, char **argv)
{
    int ret;
    pthread_t tid;

    //Ensure defualt settings for FP
    _MM_SET_DENORMALS_ZERO_MODE(_MM_DENORMALS_ZERO_OFF);
    _MM_SET_FLUSH_ZERO_MODE(_MM_FLUSH_ZERO_OFF);

    reload_buf   = (unsigned char *) mmap(NULL, 2*LEAK_SIZE*STRIDE, PROT_READ | PROT_WRITE,
                                          MAP_ANONYMOUS | MAP_PRIVATE | MAP_POPULATE | MAP_HUGETLB, -1, 0);
    assert(reload_buf != MAP_FAILED);
    
    ret = mprotect(&smc_win_size, 0x1000, PROT_READ | PROT_WRITE | PROT_EXEC);
    assert(ret == 0);
    
    ret = mprotect(&xmc_win_size, 0x1000, PROT_READ | PROT_WRITE | PROT_EXEC);
    assert(ret == 0);
    
    printf("tsx_win_size:\n");
    if(check_tsx())
    {
        win_size_run(tsx_win_size);
    }
    else
    {
        printf("Not supported on this processors!\n");
    }

    printf("smc_win_size:\n");
    win_size_run(smc_win_size);
    
    printf("xmc_win_size:\n");
    tid = create_thread(TRIGGER_CORE, xmc_trigger_loop, NULL);
    usleep(2000);                                             
    win_size_run(xmc_win_size);
    cancel_thread(tid);
    
    printf("fp_win_size:\n");
    win_size_run(fp_win_size);
    
    printf("fp_win_size_branch:\n");
    win_size_run(fp_win_size_branch);
    
    printf("md_win_size:\n");
    win_size_run(md_win_size);

    printf("md_win_size_branch:\n");
    win_size_run(md_win_size_branch);
    
    tid = create_thread(TRIGGER_CORE, mo_trigger_loop, NULL);
    usleep(2000);                                             
    printf("mo_win_size:\n");
    win_size_run(mo_win_size);
    cancel_thread(tid);
   
    printf("bht_win_size:\n");
    win_size_run(bht_win_size);
    
    printf("fault_win_size:\n");
    fault_win_size_run();
}

void win_size_run(win_size_func_t win_size_func)
{
    /* Setup */
    set_cpu(EXECUTER_CORE);
    memset(results, 0, sizeof(results));

    for(int j=0; j<ITER; j++)
    {
        flush(reload_buf);
        win_size_func(reload_buf);
        reload(reload_buf, results);
    }

    print_results(results, 1);
}


void *xmc_trigger_loop(void *arg)
{
    while(1)
    {
        xmc_win_size_trigger();       
    }
}

void *mo_trigger_loop(void *arg)
{
    while(1)
    {
        mo_win_size_trigger();        
    }
}

//Code taken from https://github.com/IAIK/meltdown/blob/master/libkdump/libkdump.c
static jmp_buf buf;

static void unblock_signal(int signum __attribute__((__unused__))) {
  sigset_t sigs;
  sigemptyset(&sigs);
  sigaddset(&sigs, signum);
  sigprocmask(SIG_UNBLOCK, &sigs, NULL);
}

static void segfault_handler(int signum) {
  (void)signum;
  unblock_signal(SIGSEGV);
  longjmp(buf, 1);
}

void fault_win_size_run()
{
    if (signal(SIGSEGV, segfault_handler) == SIG_ERR)
    {
        exit(1);
    }

    memset(results, 0, sizeof(results));
    for(int j=0; j<ITER; j++)
    {
        flush(reload_buf);
        if (!setjmp(buf)) {
            fault_win_size(reload_buf);
        }
        reload(reload_buf, results);
    }

    print_results(results, 1);
}
