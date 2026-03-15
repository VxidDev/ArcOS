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
            mov cx, 1
            int 10h

        .skipremoval:
            jmp .loop

parseInput: ; parses user input and executes command based on it.
    mov si, echo
    xor bx, bx  

    .echoLoop:
        cmp bx, echoLen 
        je .execEcho

        cmp [inputBuf + bx], 0 ; check if null-terminated
        je .skipEcho

        mov al, [si + bx] ; char = *(si + cx) 
        cmp al, [inputBuf + bx]

        jne .skipEcho

        inc bx
        jmp .echoLoop  

        .execEcho:
            mov si, inputBuf
            add si, echoLen

            cmp byte [si], 0 ; check if end 
            je .nl 

            cmp byte [si], ' ' ; check if space 
            jne .skipEcho 

            inc si

            call prints

            .nl:
                call printnl 

            ret 

        .skipEcho:

    xor bx, bx 
    mov si, clear

    .clearLoop:
        cmp bx, clearLen 
        je .execClear

        cmp [inputBuf + bx], 0 ; check if null-terminated
        je .skipClear

        mov al, [si + bx] ; char = *(si + cx) 
        cmp al, [inputBuf + bx]

        jne .skipClear

        inc bx
        jmp .clearLoop  

        .execClear:
            mov si, inputBuf
            add si, clearLen

            cmp byte [si], 0 ; check if null-terminated 
            jne .skipClear 

            call clears 

            ret 

        .skipClear:
    
    xor bx, bx 
    mov si, color

    .colorLoop:
        cmp bx, colorLen 
        je .execColor

        cmp [inputBuf + bx], 0 ; check if null-terminated
        je .skipColor 

        mov al, [si + bx] ; char = *(si + cx) 
        cmp al, [inputBuf + bx]

        jne .skipColor

        inc bx
        jmp .colorLoop  

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
            
    mov si, commandNotFound
    mov bl, 0x04

    call printcs
    call printnl

    ret   
