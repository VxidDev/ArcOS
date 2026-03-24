bgconfig: ; configure system's background color. | usage: si = string e.g "1"
    .skipWhitespace:
        cmp byte [si], ' '
        jne .parse 

        inc si 

        jmp .skipWhitespace

    .parse:
        call atoi

        cmp ax, 0
        jl .inv

        cmp ax, 15 
        jg .inv 

    .convert: ; to make ax 0x<0-15>0 instead of 0x0<0-15>.
        shl ax, 4

    mov [currentBg], al 
    call clears
    
    jmp .end 

    .inv:
        mov si, bgconfig_invBg
        mov ah, 0x01 ; sys_print_string 
        int 0x80

        mov ah, 0x02 ; sys_print_newline
        int 0x80

        ret

    .end:
        ret 

bgconfigCmd: db "bgconfig"
bgconfigCmdLen equ $ - bgconfigCmd

bgconfig_invBg: db "bgconfig: invalid background code.", 0
