userInput: ; take input from user. limited to 32 bytes. | si = buffer
    mov di, si 
    add di, 32

    call getcrsr

    .loop:
        call getchar

        cmp al, 0x0D ; check if enter
        je .enter

        cmp al, 0x08 ; check if backspace
        je .backspace 

        cmp si, di ; check if user had inputted 32 bytes
        je .skip  

        mov byte [si], al ; store character
        inc si 

        mov ah, 09h
        mov bh, 0
        mov bl, [currColor]
        add bl, [currentBg]
        mov cx, 1
        int 10h

        inc dl 
        call mvcrsr

        .skip:  

        jmp .loop

        .enter:
            mov byte [si] , 0 ; null-terminate
            ret   

        .backspace:
            mov ax, di
            sub ax, 32          
            cmp si, ax

            je .skipremoval     

            dec si              ; move buffer pointer back

            ; move cursor back
            call getcrsr
            dec dl
            call mvcrsr

            ; erase character on screen
            mov ah, 09h
            mov al, ' '
            mov bh, 0
            mov bl, [currColor]
            add bl, [currentBg]
            mov cx, 1
            int 10h

        .skipremoval:
            jmp .loop

parseInput: ; parses user input and executes command based on it.
    mov si, echo
    mov di, inputBuf 
    mov bx, echoLen

    call memcmp_n   

    cmp al, 0
    je .skipEcho

    .execEcho:
        mov si, inputBuf
        add si, echoLen

        cmp byte [si], 0 ; check if end 
        je .nl 

        cmp byte [si], ' ' ; check if space 
        jne .skipEcho 

        inc si

        mov ah, 0x01
        int 0x80

        .nl:
            mov ah, 0x02 
            int 0x80

        ret 

    .skipEcho:

    mov si, clear
    mov bx, clearLen

    call memcmp_n   

    cmp al, 0
    je .skipClear

    .execClear:
        mov si, inputBuf
        add si, clearLen

        cmp byte [si], 0 ; check if null-terminated 
        jne .skipClear 

        call clears 

        ret 

    .skipClear:
    
    mov si, color 
    mov bx, colorLen

    call memcmp_n   

    cmp al, 0 
    je .skipColor

    .execColor:
        mov si, inputBuf
        add si, colorLen    

        cmp byte [si], ' '   
        jne .defaultColor
        inc si               ; move past the space

        call strhex 
        mov [currColor], al

        jmp .doneColor 

    .defaultColor:
        mov [currColor] , 0x07
        ret

    .doneColor:
        ret

    .skipColor:

    mov si, shutdown
    mov bx, shutdownLen

    call memcmp_n   

    cmp al, 0 
    je .skipShutdown

    .execShutdown:
        mov si, inputBuf
        add si, shutdownLen    

        cmp byte [si], 0   
        jne .skipShutdown

        mov ah, 0xA0
        int 0x80

        ret

    .skipShutdown:

    mov si, reboot
    mov bx, rebootLen

    call memcmp_n 

    cmp al, 0
    je .skipReboot  

    .execReboot:
        mov si, inputBuf
        add si, rebootLen    

        cmp byte [si], 0   
        jne .skipReboot

        mov ah, 0xA1
        int 0x80

        ret

    .skipReboot:

    mov si, calcCmd
    mov bx, calcLen

    call memcmp_n   

    cmp al, 0
    je .skipCalc

    .execCalc:
        mov si, inputBuf
        add si, calcLen    

        cmp byte [si], ' '   
        jne .defaultCalc
        inc si ; move past the space
 
        call calc 
        
        ret

    .defaultCalc:
        cmp byte [si], 0
        ret

    .skipCalc:

    mov si, timeCmd 
    mov bx, timeLen

    call memcmp_n   

    cmp al, 0
    je .skipTime

    .execTime:
        mov si, inputBuf
        add si, timeLen    

        cmp byte [si], 0   
        jne .skipTime 
        
        call time
        call printnl

        ret 

    .skipTime:

    mov si, tzCmd
    mov bx, tzCmdLen

    call memcmp_n   

    cmp al, 0
    je .skipTz

    .execTz:
        mov si, inputBuf
        add si, tzCmdLen    

        cmp byte [si], 0   
        je .defaultTz 
        
        call tzconfig

        ret 

    .defaultTz:
        mov [tz_offset], 0
        ret

    .skipTz:

    mov si, sleepCmd
    mov bx, sleepLen

    call memcmp_n

    cmp al, 0 
    je .skipSleep

    .execSleep:
        mov si, inputBuf
        add si, sleepLen

        cmp byte [si], 0
        je .defaultSleep

        cmp byte [si], ' '
        jne .skipSleep

        call sleep_cmd
        ret 

    .defaultSleep:
        ret

    .skipSleep:

    mov si, bgconfigCmd
    mov bx, bgconfigCmdLen

    call memcmp_n

    cmp al, 0
    je .skipBgconfig
    
    .execBgconfig:
        mov si, inputBuf
        add si, bgconfigCmdLen

        cmp byte [si], 0
        je .defaultBgconfig

        cmp byte [si], ' '
        jne .skipBgconfig

        inc si 

        call bgconfig
        ret

    .defaultBgconfig:
        mov [currentBg], 0x00 ; black 
        call clears
        ret 

    .skipBgconfig:
            
    mov si, commandNotFound
    mov bl, 0x04
    add bl, [currentBg]

    call printcs
    call printnl

    ret   
