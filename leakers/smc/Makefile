all: leak
	
FLAGS:=-DSTRIDE=0x400 -DSTRIDE_LOG=10 -DLEAK_SIZE=256 -DLEAK_SIZE_LOG=8 -DITER=1000

leak: leak.c smc.S
	nasm -f elf64 smc.S -o smc.o -I ../../common $(FLAGS)
	gcc leak.c -o leak smc.o -I ../../common $(FLAGS)

clean:
	rm -f leak smc.o
