#include "common.h"

int main()
{
    ALLOC()

    //         N    Store   Load
    call_st_ld(100, 0,      0);  
    call_st_ld(20,  0,      64);
    call_st_ld(20,  0,      0);
        
    print_counters(iter);

    fflush(stdout);
    return 0;    
}
