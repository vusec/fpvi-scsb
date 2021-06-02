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
#include <time.h>
#include "helper.h"
#include "flush_reload.h"

#define SECRET_SIZE     1024*1024*(8/LEAK_SIZE_LOG)
#define EXECUTER_CORE   0
#define TRIGGER_CORE    1
#define MAX_RETRIES     128

/* ASM FUNCTIONS */
typedef uint64_t leak_func_t(uint8_t *reload_buf, uint8_t *leak_ptr);
extern leak_func_t flush_reload_leak; 
extern leak_func_t smc_leak; 
extern leak_func_t fp_leak; 
extern leak_func_t md_leak; 
extern leak_func_t bht_leak; 
extern leak_func_t tsx_leak; 
extern leak_func_t xmc_leak; 
extern leak_func_t mo_leak; 
extern leak_func_t fault_leak; 

extern void xmc_leak_trigger(void);
extern void mo_leak_trigger(void);

/* GLOBAL VARIABLES */
__attribute__((aligned(4096))) size_t  results[LEAK_SIZE] = {0};
__attribute__((aligned(4096))) uint8_t secret[SECRET_SIZE];
uint8_t *reload_buf;
static jmp_buf buf;                                                               

/* PROTOTYPES */
double leak_run(leak_func_t leak);
double leak_run_fault(leak_func_t leak);
void *xmc_trigger_loop(void *arg);
void *mo_trigger_loop(void *arg);

//Code taken from https://github.com/IAIK/meltdown/blob/master/libkdump/libkdump.c
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

int main(int argc, char **argv)
{
    int ret, fp;
    pthread_t tid;

    //Ensure defualt settings for FP
    _MM_SET_DENORMALS_ZERO_MODE(_MM_DENORMALS_ZERO_OFF);
    _MM_SET_FLUSH_ZERO_MODE(_MM_FLUSH_ZERO_OFF);

    //F+R Setup
    reload_buf   = (unsigned char *) mmap(NULL, 2*LEAK_SIZE*STRIDE, PROT_READ | PROT_WRITE,
            MAP_ANONYMOUS | MAP_PRIVATE | MAP_POPULATE | MAP_HUGETLB, -1, 0);
    assert(reload_buf != MAP_FAILED);
    memset(results, 0, sizeof(results));

    //Make the SMC code pages RWX
    ret = mprotect(&smc_leak, 0x1000, PROT_READ | PROT_WRITE | PROT_EXEC);
    assert(ret == 0);
    ret = mprotect(&xmc_leak, 0x1000, PROT_READ | PROT_WRITE | PROT_EXEC);
    assert(ret == 0);
    
    assert(signal(SIGSEGV, segfault_handler) != SIG_ERR);

    //Generate random secret to leak
    fp = open("/dev/urandom", O_RDONLY);
    ret = read(fp, secret, SECRET_SIZE);
    assert(ret == SECRET_SIZE);

    printf("%20s;%20s;%20s;%20s;\n", "Exception Suppr.", "Time [s]", "Leak Rate [Mb/s]", "no_hit");

    //Run Experiments
    printf("%20s;", "fr");
    leak_run(flush_reload_leak);

    if(check_tsx())
    {
        printf("%20s;", "tsx");
        leak_run(tsx_leak);
    }

    printf("%20s;", "smc");
    leak_run(smc_leak);

    printf("%20s;", "fp");
    leak_run(fp_leak);

    printf("%20s;", "md");
    leak_run(md_leak);

    printf("%20s;", "bht");
    leak_run(bht_leak);

    printf("%20s;", "xmc");
    tid = create_thread(TRIGGER_CORE, xmc_trigger_loop, NULL);
    usleep(2000);
    leak_run(xmc_leak);
    cancel_thread(tid);

    printf("%20s;", "mo");
    tid = create_thread(TRIGGER_CORE, mo_trigger_loop, NULL);
    usleep(2000);
    leak_run(mo_leak);
    cancel_thread(tid);
    
    printf("%20s;", "fault");
    leak_run_fault(fault_leak);

    return 0;
}

double leak_run(leak_func_t leak)
{
    int correct;
    int no_hit;
    struct timespec before, after;

    set_cpu(EXECUTER_CORE);
    no_hit = 0;

    clock_gettime(CLOCK_REALTIME, &before);
    for(int i=0; i<SECRET_SIZE; i++)
    {
        memset(results, 0, sizeof(results));
        correct = secret[i]&LEAK_MASK;

        for(int j=0; j<MAX_RETRIES; j++)
        {
            flush(reload_buf);
            leak(reload_buf, &secret[i]);
            reload(reload_buf, results);
            if(results[correct] != 0) break;
        }

        if(results[correct] == 0)
        {   
            //printf("0x%04x ", i);
            no_hit++;
        }
    }
    clock_gettime(CLOCK_REALTIME, &after);

    double time = after.tv_sec - before.tv_sec + (after.tv_nsec - before.tv_nsec) / 1000000000.0;
    double rate = (double)((SECRET_SIZE-no_hit)*LEAK_SIZE_LOG/time)/(1024*1024);
    printf("%20.3f;%20.3f;%20d;\n",
            time,
            rate,
            no_hit
          );

    return rate;
}

void *xmc_trigger_loop(void *arg)
{
    while(1)
    {
        xmc_leak_trigger();
    }
}

void *mo_trigger_loop(void *arg)
{
    while(1)
    {
        mo_leak_trigger();
    }
}

double leak_run_fault(leak_func_t leak)
{
    int correct;
    int no_hit;
    struct timespec before, after;

    set_cpu(EXECUTER_CORE);
    no_hit = 0;

    clock_gettime(CLOCK_REALTIME, &before);
    for(int i=0; i<SECRET_SIZE; i++)
    {
        memset(results, 0, sizeof(results));
        correct = secret[i]&LEAK_MASK;

        for(int j=0; j<MAX_RETRIES; j++)
        {
            flush(reload_buf);
            if (!setjmp(buf)) {                                                       
                leak(reload_buf, &secret[i]);
            }
            reload(reload_buf, results);
            if(results[correct] != 0) break;
        }

        if(results[correct] == 0)
        {   
            //printf("0x%04x ", i);
            no_hit++;
        }
    }
    clock_gettime(CLOCK_REALTIME, &after);

    double time = after.tv_sec - before.tv_sec + (after.tv_nsec - before.tv_nsec) / 1000000000.0;
    double rate = (double)((SECRET_SIZE-no_hit)*LEAK_SIZE_LOG/time)/(1024*1024);
    printf("%20.3f;%20.3f;%20d;\n",
            time,
            rate,
            no_hit
          );

    return rate;
}
