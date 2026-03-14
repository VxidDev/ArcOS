mvcrsr: ; move cursor to given position. | usage: dh = row , dl = column
    mov ah, 0x02 ; set cursor pos 
    mov bh, 0 ; page 
    int 0x10 

    ret

getcrsr: ; get cursor position.
    mov ah, 0x03
    mov bh, 0 
    int 0x10

    ret