tzconfig: ; set tz_offset to provide accurate time. (progs/time.s) | usage: si = input string
    .skipWhitespace:
        cmp byte [si], ' '
        jne .doneSkippingWhitespace

        inc si 
        jmp .skipWhitespace

        .doneSkippingWhitespace:

    .preAtoiCheck:
        mov cx, si ; preserve si
        .checkLoop:
            cmp byte [si], 0
            je .updateOffset

            cmp byte [si], '-'
            je .skipValidation

            cmp byte [si], '0'
            jl .inv

            cmp byte [si], '9'
            jg .inv 

            .skipValidation:
                inc si 

            jmp .checkLoop

    .updateOffset:
        mov si, cx 
        call atoi

        cmp ax, 14
        jg .inv 

        cmp ax, -12
        jl .inv  

        mov byte [tz_offset], al  
        jmp .end

    .inv:
        mov si, tz_invOffset
        mov ah, 0x01
        int 0x80

        mov ah, 0x02 
        int 0x80

    .end:
        ret