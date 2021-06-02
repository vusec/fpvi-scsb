SECTION .text
GLOBAL st_ld
GLOBAL pc_unaligned_st_ld
GLOBAL pc_aligned_st_ld
%include "counters.S"


ALIGN 4096
;rdi: store addr
;rsi: load  addr
st_ld:

    START_COUNTERS

    lfence

%rep 10
    ;imul trick to delay the store address
    imul    rdi, 1
%endrep

    mov     BYTE [rdi], 0x42        ;Store
    mov     al, BYTE [rsi]          ;Load

%rep 10
    ;use the loaded value to make it more visible in timing
    imul    eax, 1
%endrep

    STOP_COUNTERS



ALIGN 4096
;rdi: store addr
;rsi: load  addr
;Add a single NOP to make the load/store no more at the same addr
pc_unaligned_st_ld:

    START_COUNTERS

    lfence

    nop     

%rep 10
    ;imul trick to delay the store address
    imul    rdi, 1
%endrep

    mov     BYTE [rdi], 0x42        ;Store
    mov     al, BYTE [rsi]          ;Load

%rep 10
    ;use the loaded value to make it more visible in timing
    imul    eax, 1
%endrep

    STOP_COUNTERS

ALIGN 4096
;rdi: store addr
;rsi: load  addr
;Same code as hoisting_test, but at a different address
pc_aligned_st_ld:

    START_COUNTERS

    lfence


%rep 10
    ;imul trick to delay the store address
    imul    rdi, 1
%endrep

    mov     BYTE [rdi], 0x42        ;Store
    mov     al, BYTE [rsi]          ;Load

%rep 10
    ;use the loaded value to make it more visible in timing
    imul    eax, 1
%endrep

    STOP_COUNTERS
