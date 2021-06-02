#include "common.h"

int main()
{
    ALLOC()

    //         N    Store   Load
    call_st_ld(20,  0,      0);  
    call_st_ld(20,  0x1000, 0x1000);
    call_st_ld(20,  0,      0x1000);
        
    print_counters(iter);

    fflush(stdout);
    return 0;    
}
