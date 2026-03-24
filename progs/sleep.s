sleep_cmd: ; sleep for given amount of seconds | usage: si = string e.g "15"
    .skipWhitespace:
        cmp byte [si], ' '
        jne .parse 

        inc si 
        jmp .skipWhitespace

    .parse:
        call atoi ; now ax supposed to store parsed number 

        cmp ax, 0
        je .inv

    .convertToTicks:
        ; ax is already set 
        mov cx, 18 ; approximate for number of ticks in 1 second 
        xor dx, dx 
        mul cx ; dx:ax * cx

    call sleep
    jmp .end 

    .inv:
        mov si, sleep_invSleepTime
        mov ah, 0x01 ; sys_print_string 
        int 0x80

        mov ah, 0x02 ; sys_print_newline
        int 0x80

    .end:
        ret

sleepCmd: db "sleep"
sleepLen equ $ - sleepCmd 
sleep_invSleepTime: db "sleep: sleep time must not be negative.", 0