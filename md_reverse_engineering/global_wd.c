#include "common.h"

int main()
{
    ALLOC()

    for(int i=0; i<10; i++) {
        for(int j=0; j<16; j++) {
            counters[iter++] = st_ld(mem+0x100, mem+0x140);
        }
        counters[iter++] = st_ld(mem+0x100, mem+0x100);
    }
    
    print_counters(iter);

    fflush(stdout);
    return 0;    
}
