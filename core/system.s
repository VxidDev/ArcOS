shtdwn: ; shutdown PC.
    mov ax, 0x5301      ; APM installation check
    xor bx, bx
    int 0x15
    jc .apm_failed       ; carry = error

    mov ax, 0x530E      ; connect to APM 
    xor bx, bx
    int 0x15
    jc .apm_failed

    mov ax, 0x5307      ; set power state
    mov bx, 0x0001      ; all devices
    mov cx, 0x0003      ; power off
    int 0x15

    ; If BIOS worked, system should power off here

    ; VM fallpack
    .apm_failed:
        mov dx, 0x604
        mov ax, 0x2000
        out dx, ax

    ; fallback
    .hang:
        hlt
        jmp .hang