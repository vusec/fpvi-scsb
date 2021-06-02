all: leak
	
FLAGS:=-DSTRIDE=0x400 -DSTRIDE_LOG=10 -DLEAK_SIZE=256 -DLEAK_SIZE_LOG=8 -DITER=1000

leak: leak.c fp.S
	nasm -f elf64 fp.S -o fp.o -I ../../common $(FLAGS)
	gcc leak.c -o leak fp.o -I ../../common -no-pie $(FLAGS)

clean:
	rm -f leak fp.o
