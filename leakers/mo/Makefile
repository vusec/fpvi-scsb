all: leak
	
FLAGS:=-DSTRIDE=0x400 -DSTRIDE_LOG=10 -DLEAK_SIZE=256 -DLEAK_SIZE_LOG=8 -DITER=1000

leak: leak.c mo.S
	nasm -f elf64 mo.S -o mo.o -I ../../common $(FLAGS)
	gcc leak.c -o leak mo.o -I ../../common ../../common/*.o -no-pie -pthread $(FLAGS)

clean:
	rm -f leak mo.o
