SECTION .text
GLOBAL st_ld

ALIGN 4096
;rdi: store addr
;rsi: load  addr
st_ld:
    
    mfence

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Start counters
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov  rcx,  0
    rdpmc
    mov  r14d, eax

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

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Stop counters
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov  rcx, 0
    rdpmc
    sub eax, r14d
    ret


;rdi = r12 = number load to train
;rsi = r13 = mem
global experiment
experiment:
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    push rcx

    ;Save parameters
    mov r12, rdi
    mov r13, rsi

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; watchdog training
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov r10, 50
no_hoisting:
    mov r11, 15
    inner_no_hoisting:
        mov rdi, r13
        lea rsi, [r13 + 64]
        call st_ld
        dec r11
        cmp r11, 0
        jne inner_no_hoisting

    mov rdi, r13
    mov rsi, r13
    call st_ld

    dec r10
    cmp r10, 0
    jne no_hoisting

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; increment global disamb counter
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
increment_global:
        mov rdi, r13
        lea rsi, [r13 + 64]
        call st_ld
        dec r12
        cmp r12, 0
        jne increment_global
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Measure the total MC
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov r12, 0      ;total mc counter
    mov r10, 10
measure_outer:
    ;Cause machine clear
    mov rdi, r13
    mov rsi, r13
    call st_ld
    add r12d, eax

    ;Bring per-addr predictor to hoisting prediction
    mov r11, 15
    measure_inner:
        mov rdi, r13
        lea rsi, [r13 + 64]
        call st_ld
        dec r11
        cmp r11, 0
        jne measure_inner

    dec r10
    cmp r10, 0
    jne measure_outer

    mov eax, r12d

    pop rcx
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    ret 




