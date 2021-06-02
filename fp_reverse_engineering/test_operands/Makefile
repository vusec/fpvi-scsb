all: test_operands

#by default
ARCH = x86

test_operands: test_operands.c $(ARCH)/snippet.S
	gcc test_operands.c $(ARCH)/snippet.S -I$(ARCH)/ -D$(ARCH) -o test_operands -O3

clean:
	rm -f test_operands
