userInput: ; take input from user. limited to 32 bytes. | si = buffer
    .loop:
        call getchar

        cmp al, 0x0D ; check if enter
        je .enter 

        mov byte [si], al ; store character
        inc si 

        mov ah, 0x0E ; Teletype Output
        int 0x10  

        jmp .loop

        .enter:
            mov si , 0 ; null-terminate
            ret   
