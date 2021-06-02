#ifndef __MC_HELPER__
#define __MC_HELPER__

void set_cpu(int core_idx);
pthread_t create_thread(int core_idx, void *(*target_loop) (void *), void *arg);
void cancel_thread(pthread_t tid);
int  check_tsx();

#endif
