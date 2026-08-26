mov ax , 01h
mov si , msg
int 80h

retf

msg db "Hello, World!" , 0
