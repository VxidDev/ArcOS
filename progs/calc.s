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

        inc bx 
        jmp .firstNumLoop

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
        xor dx, dx 
        mov ax, [calc_firstNum]
        mov cx, [calc_secondNum]
        idiv cx 

        mov cx, ax

        jmp .print 

    .print:
        mov ax, cx
        mov si, calc_itoaBuf
        mov bx, 6
        call itoa

        mov si, calc_itoaBuf
        add si, bx
        sub si, di

        mov ah, 0x01
        int 0x80

        mov ah, 0x02
        int 0x80

        ret

