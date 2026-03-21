calc: ; parse an input string (si) and prints value. | example string: "1 + 5" -> "6"
    xor bx, bx ; counter 

    .skipInitialWhitespace:
        cmp byte [si + bx], ' ' ; check if whitespace
        jne .firstNumLoop

        inc bx 
        jmp .skipInitialWhitespace

    .firstNumLoop:
        cmp byte [si + bx], ' ' ; check if whitespace
        je .nullTerminate

        cmp byte [si + bx], '-'
        je .skipValidation

        cmp byte [si + bx], '0'
        jl .checkOper 

        cmp byte [si + bx], '9'
        jg .checkOper 

        .skipValidation:
            inc bx 
            jmp .firstNumLoop

    .checkOper:
        cmp byte [si + bx], '+'
        je .setOper

        cmp byte [si + bx], '-'
        je .setOper 

        cmp byte [si + bx], '/'
        je .setOper 

        cmp byte [si + bx], '*'
        je .setOper

        jmp .inv

        .setOper:
            mov al, byte [si + bx]
            mov [calc_operator], al

            inc si
            add si, bx 

            jmp .saveSecondNum

    .nullTerminate:
        mov byte [si + bx], 0 ; null-terminate
        call atoi

        mov [calc_firstNum], ax
        add si, bx ; skip the first number,string is "1\0+ 5" ("+ 5")

    .oper:
        cmp si, ' ' ; check if whitespace 
        je .skip 

        inc si

        .skip:

        mov al, [si] 
        mov [calc_operator], al

        inc si ; si now points to whitespace after operator "+_123" ('_' is pointer's pos)

    .skipWhitespace:
        cmp byte [si], ' ' ; check if whitespace
        jne .saveSecondNum ; si now points to the start of the number 

        inc si ; skip whitespace
        jmp .skipWhitespace

    .saveSecondNum:
        mov di, si ; preserve si 

        .checkValid:
            cmp byte [si], 0 
            je .valid

            cmp byte [si], '-'
            je .skipCheck

            cmp byte [si], '0'
            jl .inv  

            cmp byte [si], '9'
            jg .inv

            .skipCheck:

            jmp .incSi

            .incBoth:
                inc di

            .incSi:
                inc si

            jmp .checkValid

        .valid:
            mov si, di

        call atoi
        mov [calc_secondNum], ax

    .processOper:
        cmp byte [calc_operator], '+'
        je .add

        cmp byte [calc_operator], '-'
        je .sub

        cmp byte [calc_operator], '*'
        je .mul

        cmp byte [calc_operator], '/'
        je .div

        mov si, calc_unknownOper
        mov ah, 0x01
        int 0x80

        mov ah, 0x02
        int 0x80

        ret 

    .add:
        mov cx, [calc_firstNum]
        add cx, [calc_secondNum]

        jmp .print 

    .sub: 
        mov cx, [calc_firstNum]
        sub cx, [calc_secondNum]

        jmp .print 

    .mul:
        mov cx, [calc_firstNum]
        imul cx, [calc_secondNum]
        jmp .print 

    .div:
        cmp [calc_secondNum], 0
        je .divZeroErr

        xor dx, dx 
        mov ax, [calc_firstNum]
        mov cx, [calc_secondNum]
        idiv cx 

        mov cx, ax

        jmp .print 

    .print:
        mov ax, cx
        mov si, calc_itoaBuf
        mov bx, 7
        call itoa

        mov si, calc_itoaBuf
        add si, bx
        sub si, di

        mov ah, 0x01
        int 0x80

        mov ah, 0x02
        int 0x80

        ret

    .inv:
        mov si, calc_invNum
        mov ah, 0x01
        int 0x80

        mov ah, 0x02
        int 0x80

        ret

    .divZeroErr:
        mov si, calc_divByZero
        mov ah, 0x01 
        int 0x80

        mov ah, 0x02
        int 0x80

        ret

