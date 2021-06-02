all: leak
	
FLAGS:=-DSTRIDE=0x400 -DSTRIDE_LOG=10 -DLEAK_SIZE=256 -DLEAK_SIZE_LOG=8 -DITER=1000

leak: leak.c xmc.S
	nasm -f elf64 xmc.S -o xmc.o -I ../../common $(FLAGS)
	gcc leak.c -o leak xmc.o -I ../../common ../../common/*.o -no-pie -pthread $(FLAGS)

clean:
	rm -f leak xmc.o
