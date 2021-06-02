#include "common.h"

int main()
{
    ALLOC()

    //                      N    Store   Load
                 call_st_ld(50,  16,     16);  
    call_pc_unaligned_st_ld(50,  16,     32);
                 call_st_ld(50,  16,     16);  
        
    print_counters(iter);

    fflush(stdout);
    return 0;    
}
