#!/bin/bash

#Some experiments need huge page tables enabled
echo 16 | sudo tee  /proc/sys/vm/nr_hugepages 1>/dev/null

#Setting the governor to performance usually reduce noise
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 1>/dev/null
