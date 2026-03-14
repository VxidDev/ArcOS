userInput: ; take input from user. limited to 32 bytes. | si = buffer
    mov di, si 
    add di, 32

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

        mov ah, 0x0E ; Teletype Output
        int 0x10

        .skip:  

        jmp .loop

        .enter:
            mov si , 0 ; null-terminate
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
            mov bl, 0x07
            mov cx, 1
            int 10h

        .skipremoval:
            jmp .loop
