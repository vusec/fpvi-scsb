all: exception_suppression leak_rate_1 leak_rate_4 leak_rate_8
	
ASM_FILES = $(wildcard *.S)
FLAGS_WIN$:=-DSTRIDE=0x400   -DSTRIDE_LOG=10 -DLEAK_SIZE=256 -DLEAK_SIZE_LOG=8 -DITER=10000
FLAGS_LEAK_1:=-DSTRIDE=0x400 -DSTRIDE_LOG=10 -DLEAK_SIZE=2   -DLEAK_SIZE_LOG=1 -DITER=10000
FLAGS_LEAK_4:=-DSTRIDE=0x400 -DSTRIDE_LOG=10 -DLEAK_SIZE=256 -DLEAK_SIZE_LOG=8 -DITER=10000
FLAGS_LEAK_8:=-DSTRIDE=0x400 -DSTRIDE_LOG=10 -DLEAK_SIZE=16  -DLEAK_SIZE_LOG=4 -DITER=10000
C_FLAGS:=-O3 -g -Wall -pthread -no-pie -I../common ../common/*.o

#Asm files must be recompiled every time to incorporate the correct FLAGS
exception_suppression: exception_suppression.c *.S
	for asm_file in ${ASM_FILES} ; do nasm -f elf64 $$asm_file  -I ../common $(FLAGS_WIN); done
	gcc exception_suppression.c -o exception_suppression *.o ${C_FLAGS} ${FLAGS_WIN}

leak_rate_1: leak_rate.c *.S
	for asm_file in ${ASM_FILES} ; do nasm -f elf64 $$asm_file  -I ../common $(FLAGS_LEAK_1); done
	gcc leak_rate.c -o leak_rate_1 *.o ${C_FLAGS} ${FLAGS_LEAK_1}

leak_rate_4: leak_rate.c *.S
	for asm_file in ${ASM_FILES} ; do nasm -f elf64 $$asm_file  -I ../common $(FLAGS_LEAK_4); done
	gcc leak_rate.c -o leak_rate_4 *.o ${C_FLAGS} ${FLAGS_LEAK_4}

leak_rate_8: leak_rate.c *.S
	for asm_file in ${ASM_FILES} ; do nasm -f elf64 $$asm_file  -I ../common $(FLAGS_LEAK_8); done
	gcc leak_rate.c -o leak_rate_8 *.o ${C_FLAGS} ${FLAGS_LEAK_8}

clean:
	rm -f *.o exception_suppression leak_rate_1 leak_rate_4 leak_rate_8
