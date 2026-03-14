prints: ; prints a singular singular string | usage: si = string
    cld ; clear direction flag to ensure that SI will increment instead of decrementing.

    .loop:
        lodsb

        cmp al, 0 ; check if loaded character is '\0'.
        je .end

        mov ah, 0x0E ; Teletype Output
        int 0x10 ; BIOS interrupt

        jmp .loop

        .end:
            ret

printcs: ; prints a colored, singular string. | usage: si = string , bl = color.
    cld ; clear direction flag to ensure that SI will increment instead of decrementing.
    call getcrsr ; get cursor position

    .loop:
        lodsb

        cmp al, 0 ; check if loaded character is '\0'.
        je .end

        mov ah, 0x09
        mov bh, 0 ; page
        mov cx, 1 ; times to print
        int 0x10

        inc dl 
        call mvcrsr

        jmp .loop

        .end:
            ret

clears: ; clear screen.
    mov ah, 0x00 ; set video mode 
    mov al, 0x03 ; to 3
    int 0x10 ; BIOS interrupt

    ret