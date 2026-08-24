[org 0x0000]

mov ah, 0x01
mov si, msg
int 0x80

mov ah, 0x02
int 0x80

retf

msg: db "Hello, World!", 0
