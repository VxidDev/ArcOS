strhex: ; convert string to hex. | usage: si = string
    xor ax, ax
    xor bh, bh
    add si, 2

    .loop:
        mov bl, [si]
        cmp bl, 0
        je .done

        shl ax, 4

        cmp bl, '0'
        jb .done
        cmp bl, '9'
        jbe .digit

        cmp bl, 'a'
        jb .checkUpper
        cmp bl, 'f'
        jbe .lower

    .checkUpper:
        cmp bl, 'A'
        jb .done
        cmp bl, 'F'
        ja .done
        sub bl, 'A' - 10
        jmp .add

    .lower:
        sub bl, 'a' - 10
        jmp .add

    .digit:
        sub bl, '0'

    .add:
        add ax, bx
        inc si
        jmp .loop

    .done:
        ret

atoi: ; convert ascii string into 16-bit integer. | usage: si = null-terminated string | ax = output
    xor ax, ax ; clear ax
    xor bx, bx ; counter
    xor cx, cx ; temp 
    xor dx, dx ; sign flag (0 = +, 1 = -)

    mov cl, [si + bx]

    cmp cl, '-'
    jne .loop

    mov dx, 1 ; set negative flag
    inc bx    ; skip '-'

    .loop:
        mov cl, [si + bx] ; load byte

        cmp cl, 0 ; check if null-terminated
        je .end 

        cmp cl, '-'
        je .inc 

        imul ax, 10
        sub cl, '0' ; subtract '0' to get true value

        xor ch, ch  ; cx = digit

        mov cl, cl
        mov ch, 0

        add ax, cx

        .inc:  
            inc bx 
            jmp .loop 

    .end:
        cmp dx, 0
        je .done

        neg ax

    .done:
        ret

itoa: ; convert 16-bit integer into ascii string. | usage: si = buffer, ax = 16-bit int, bx = buffer length | di = bytes converted.
    mov [itoa_isNeg], 0

    xor di, di ; counter 
    mov cx, 10 ; constant for division

    push bx ; save value of bx
    dec bx ; reserve single character for null-termination.

    cmp ax, 0 
    je .returnZeroChar

    jl .neg
    jmp .loop

    .neg:
        neg ax
        mov [itoa_isNeg], 1 

    .loop:
        xor dx, dx ; clear for DX:AX division.

        cmp ax, 0 ; check if zero
        je .end 

        idiv cx ; divide DX:AX by 10
        add dl, 48 ; convert raw value into ASCII character

        mov byte [si + bx], dl

        dec bx
        inc di

        jmp .loop

        .end:
            cmp byte [itoa_isNeg], 1
            jne .nullTerm

            inc di
            mov byte [si + bx], '-'

            .nullTerm:
                pop bx 
                mov byte [si + bx], 0 ; null-terminate
                ret 
    
    .returnZeroChar:
        mov byte [si + bx], 0
        dec bx 
        mov byte [si + bx], 48 ; '0'
        add di, 2

        pop bx

        ret
