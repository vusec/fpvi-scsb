#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>

extern uint32_t experiment(uint64_t t, uint8_t *mem);


int main()
{
    uint8_t *mem = (unsigned char *) mmap(NULL, 10*0x1000, PROT_READ | PROT_WRITE,  (MAP_ANONYMOUS | MAP_PRIVATE | MAP_POPULATE), -1, 0);

    for(int i=1; i<400; i++)
    {
        printf("%d;%d\n", i, experiment(i, mem));
    }

    return 0;    
}
