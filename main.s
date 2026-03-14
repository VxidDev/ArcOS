[org 0x7C00]
[bits 16]

global _start

_start:
    cli ; disable interrupts

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    sti ; enable interrupts
    
    call clears

    mov dh, 12
    mov dl, 28
    call mvcrsr

    mov si, greetingPt1
    mov bl, 0x0F
    call printcs

    mov si, greetingPt2
    mov bl, 0x0B
    call printcs 

    mov si, greetingPt3
    mov bl, 0x03
    call printcs 

    mov si, greetingPt4 
    mov bl, 0x0F
    call printcs

    jmp $

%include "core/output.s" ; provides prints , printcs , clears
%include "core/cursor.s" ; provides mvcrsr

greetingPt1: db "Welcome to ", 0
greetingPt2: db "Arc", 0
greetingPt3: db "OS", 0
greetingPt4: db "!", 0

times 510 - ($ - $$) db 0
dw 0xAA55

