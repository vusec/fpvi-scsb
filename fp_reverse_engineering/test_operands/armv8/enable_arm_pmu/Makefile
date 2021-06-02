obj-m	:= enable_arm_pmu.o
PWD	:= $(shell pwd)

KERN = /lib/modules/$(shell uname -r)/build

all:
	make -C $(KERN) M=$(PWD) modules
clean:
	make -C $(KERN) M=$(PWD) clean
