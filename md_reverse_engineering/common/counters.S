%macro START_COUNTERS 0

    ;Save registers on stack
    push    rbx
    push    r11
    push    r12
    push    r13
    push    r14
    push    r15

    ;Save the 3rd parameter to r12
    mov     r12, rdx
    ;Save the 4th parameter to r11
    mov     r11, rcx

 
    ;Read perf counter #0
    mov  rcx,  0
    rdpmc
    lfence
    mov  r13d, eax

    ;Read perf counter #1
    mov  rcx,  1
    rdpmc
    lfence
    mov  r14d, eax
    
    ;Read timestamp
    rdtscp
    mov  r15d,  eax

%endmacro


%macro STOP_COUNTERS 0

    ;Read timestamp
    rdtscp
    sub  eax, r15d
    mov  r15d, eax

    ;Read perf counter #1
    mov  rcx, 1
    rdpmc
    lfence
    sub eax, r14d
    mov  r14d, eax
    
    ;Read perf counter #0
    mov  rcx, 0
    rdpmc
    lfence
    sub eax, r13d
    mov  r13d, eax

    ;Pack the 3 counters in a uint64_t return value as follow:
    ;64         48          32          16          0
    ;---PERF1----|---PERF0---|---------TIME---------|
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    mov eax, r15d
    mov ebx, r14d
    mov ecx, r13d
    shl rbx, 32
    shl rcx, 48
    or  rax, rbx 
    or  rax, rcx

    ;Pop saved registers values and return
    pop    r15
    pop    r14
    pop    r13
    pop    r12
    pop    r11
    pop    rbx
    ret

%endmacro
