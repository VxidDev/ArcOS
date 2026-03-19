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

rbt: ; reboot PC.
    cli                 ; disable interrupts

    .waitInput:
        in al, 0x64     ; read status register
        test al, 0x02   ; input buffer full?
        jnz .waitInput ; wait until empty

    mov al, 0xFE        ; reset command
    out 0x64, al

    hlt                 ; just in case