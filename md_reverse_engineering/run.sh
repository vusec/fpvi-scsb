#!/bin/bash

#Wrapper taken from nanobench https://github.com/andreas-abel/nanoBench

is_intel=$(cat /proc/cpuinfo | grep "model name" | grep -io intel)

if [ "$EUID" -ne 0 ]; then
    echo "Run with sudo"
    exit 1
fi

if ! command -v rdmsr &>/dev/null; then
    echo "msr-tools are required"
    exit 1
fi

prev_rdpmc=$(cat /sys/bus/event_source/devices/cpu/rdpmc)
echo 2 > /sys/bus/event_source/devices/cpu/rdpmc || exit

modprobe --first-time msr &>/dev/null
msr_prev_loaded=$?

# (Temporarily) disable watchdogs, see https://github.com/obilaniu/libpfc
! modprobe --first-time -r iTCO_wdt &>/dev/null
iTCO_wdt_prev_loaded=$?

! modprobe --first-time -r iTCO_vendor_support &>/dev/null
iTCO_vendor_support_prev_loaded=$?

prev_nmi_watchdog=$(cat /proc/sys/kernel/nmi_watchdog)
echo 0 > /proc/sys/kernel/nmi_watchdog

###################################################
if [ -n "$is_intel" ]; then
wrmsr -a 0x38F 0x3      #enable perf counter 0 and 1
wrmsr -a 0x186 0x4102c3 #machine clear due to memory ordering
wrmsr -a 0x187 0x410109 #disambiguation reset
#wrmsr -a 0x186 0x4101c3 #machine clear any
#wrmsr -a 0x187 0x410107 #load_blocks.aliasing
#wrmsr -a 0x187 0x410209 #disambiguation success
fi

# Compile
nasm -f elf64 common/st_ld.S -o common/st_ld.o -I common/
gcc $1 -o exp -O3 -Icommon/ common/st_ld.o
taskset -c 0 ./exp

if [ -n "$is_intel" ]; then
wrmsr -a 0x38F 0x0
fi
###################################################

echo $prev_rdpmc > /sys/bus/event_source/devices/cpu/rdpmc
echo $prev_nmi_watchdog > /proc/sys/kernel/nmi_watchdog

if [[ $msr_prev_loaded == 0 ]]; then
    modprobe -r msr
fi

if [[ $iTCO_wdt_prev_loaded != 0 ]]; then
    modprobe iTCO_wdt &>/dev/null
fi

if [[ $iTCO_vendor_support_prev_loaded != 0 ]]; then
    modprobe iTCO_vendor_support &>/dev/null
fi
