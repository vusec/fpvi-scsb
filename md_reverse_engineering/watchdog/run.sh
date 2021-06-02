#!/bin/bash
echo 16 | sudo tee  /proc/sys/vm/nr_hugepages 1>/dev/null
echo 2 > /sys/bus/event_source/devices/cpu/rdpmc || exit
sudo wrmsr -a 0x38F 0x1      #enable perf counter 0
sudo wrmsr -a 0x186 0x4102c3 #machine clear due to memory ordering

nasm -f elf64 snippet.S -o snippet.o 
gcc main.c -o main snippet.o
taskset -c 0 ./main 

