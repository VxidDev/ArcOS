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