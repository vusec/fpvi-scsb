# fp_reverse_engineering 

This folder contains a test program to verify the presence of **FPVI (Floating Point Value Injection)**.

## Compilation

Depending on your processor, compilation slightly changes:

On `intel` and `amd` processors:

```
make ARCH=x86
```

On `armv8` processors:

```
make ARCH=armv8
```



## Prerequisites

On `x86` processors ensure that `HUGE_TLB` is allowed:

```
echo 16 | sudo tee  /proc/sys/vm/nr_hugepages
``` 

If supported, setting the governor to `performance` usually reduces the noise:

```
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```


On `armv8` it is required to enable precise timers access from EL0 using the provided kernel module in the folder `enable_arm_pmu`.
To enable this counter it is sufficient to compile and insert the kernel module:

```
cd enable_arm_pmu
make
sudo insmod enable_arm_pmu.ko
dmesg | tail
```



## Running the tests


### find_operands

This program allows to find FP operands to obtain transient results in the form of `0xfffbxxxxxxxxxxxx` used in the
`fpvi_firefox_exploit`. The operands are simply obtained by noticing that the mantissa of the following operations is
kept intact transiently.


```
       x = 0xbffb0deadbeef007       -1.690898e+00    (  NORMAL    biased_exp= 1023    unbiased_exp=    0    mantissa=0xb0deadbeef007)
       y = 0x0000000000000001       4.940656e-324    (DENORMAL    biased_exp=    0    unbiased_exp=-1022    mantissa=0x0000000000001)
arch_res = 0xfff0000000000000                -inf    (  NORMAL    biased_exp= 2047    unbiased_exp= 1024    mantissa=0x0000000000000)
rans_res = 0xfffb0deadbeef000                -nan    (  NORMAL    biased_exp= 2047    unbiased_exp= 1024    mantissa=0xb0deadbeef000)
                                                                                                                                     
       x = 0xbffb0deadbeef00f       -1.690898e+00    (  NORMAL    biased_exp= 1023    unbiased_exp=    0    mantissa=0xb0deadbeef00f)
       y = 0x0000000000000001       4.940656e-324    (DENORMAL    biased_exp=    0    unbiased_exp=-1022    mantissa=0x0000000000001)
arch_res = 0xfff0000000000000                -inf    (  NORMAL    biased_exp= 2047    unbiased_exp= 1024    mantissa=0x0000000000000)
rans_res = 0xfffb0deadbeef008                -nan    (  NORMAL    biased_exp= 2047    unbiased_exp= 1024    mantissa=0xb0deadbeef008)

```

### test_operands

This program allows to observe if there is a transient FP result and in case of its presence the precise transient result is printed.
The transient result is obtained by leaking one nibble at a time the FP result. 

A working run looks as follow:

```
$./test_operands 0xc000e8b2c9755600 0x0004000000000000
x = 0xc000e8b2c9755600       -2.113622e+00     (    NORMAL    biased_exp= 1024    unbiased_exp=    1    mantissa=0x0e8b2c9755600)
y = 0x0004000000000000       5.562685e-309     (  DENORMAL    biased_exp=    0    unbiased_exp=-1022    mantissa=0x4000000000000)
arch__res = 0xfff0000000000000         -inf    (    NORMAL    biased_exp= 2047    unbiased_exp= 1024    mantissa=0x0000000000000)
trans_res = 0xfffb0deadbeef000         -nan    (    NORMAL    biased_exp= 2047    unbiased_exp= 1024    mantissa=0xb0deadbeef000)
```

shows that the FP division `-2.113622e+00/5.562685e-309` generates two results:

* `-inf [0xfff0000000000000]` architecturally
* `NaN [0xfffb0deadbeef000]` speculatively

If `arch__res` and `trans_res` are equal, it means that no transient result is present.

In case of problem, setting `DEBUG` to 1 may help to observe what are the hits in the F+R for each nibble of the result.



Some examples of `x` and `y` that lead to a transient result on `intel` processors are:

```
./test_operands 0x0010123456789abc 0x4030000000000000 (arch: 0x00010123456789ac, tran: 0x3fd0123456789abc)
./test_operands 0xc000e8b2c9755600 0x0004000000000000 (arch: 0xfff0000000000000, tran: 0xfffb0deadbeef000)
./test_operands 0x0017deadbeefcafe 0x6cd0000000000000 (arch: 0x0000000000000000, tran: 0x1337deadbeefcafe)
./test_operands 0x0000000003b9cdaa 0x8000000025341b64 (arch: 0xbfb9a32edf296605, tran: 0xbfefffffbd0b6520)
./test_operands 0x000000002b047cf2 0xbfe00000528d4364 (arch: 0x800000005608f828, tran: 0x800fffffb0ee74b0)
./test_operands 0x0000000027ae1b77 0x11a0000056bce987 (arch: 0x2cf3d70d4ff1d803, tran: 0x2e4fffffa1e265d0)
./test_operands 0x338000002a5b9b3b 0x000000004e64536b (arch: 0x74ba200a066b2c3e, tran: 0x737fffffb7ee9100)
./test_operands 0xc0e00000171b70ce 0x800000006611cbe7 (arch: 0x7ff0000000000000, tran: 0x40dfffff62134db0)
```

Some examples of `x` and `y` that lead to a transient result on `amd` processors are:

```
./test_operands 0x0010123456789abc 0x4030000000000000 (arch: 0x00010123456789ac, tran: 0x3fd0123456789abc)
./test_operands 0x001deadbeef13337 0x4000000000000000 (arch: 0x000ef56df778999c, tran: 0x000deadbeef13337)
./test_operands 0x0017deadbeefcafe 0x6cd0000000000000 (arch: 0x0000000000000000, tran: 0x1337deadbeefcafe)
```


On the tested `ARM` Cortex A72 processor we were not able to reproduce the issue.


## Troubleshooting

* F+R threshold `THRESHOLD` present in the file `flush_reload.h` should be set accordingly to your system. To find a suitable value we suggest to use `libflush` https://github.com/IAIK/armageddon/tree/master/libflush
* Inside `snippet.S` the target FP division is repeated 4 times to increase the FPU pressure that, usually, leads to a wider transient window. In case of problems, a tweak to the repetition amount may help.
* On Intel processors setting the governor to `performance` usually reduce the noise
* The `assert` of `test_operands` is failing: this means that your Flush+Reload is not working, try to change the `THRESHOLD` or the `STRIDE` constants in `flush_reload.h`. Enabling `DEBUG=1` can help to debug the F+R issue.

## Tested processors:

  * Intel Core i7-10700K
  * Intel Xeon Silver 4214
  * Intel Core i9-9900K
  * Intel Core i7-7700K
  * AMD Ryzen 5 5600X 6-Core Processor
  * AMD Ryzen Threadripper 2990WX 32-Core Processor
  * AMD Ryzen 7 2700X Eight-Core Processor
  * Raspberry-pi 4B (ARM Cortex A72 - armv8)

