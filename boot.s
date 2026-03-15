[org 0x7C00]
[bits 16]

global _start

_start:
    cli ; disable interrupts

    mov [bootdrive], dl ; Save boot drive number

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    sti ; enable interrupts

    call clears

    mov si, bootMsgPt1
    mov bl, 0x0F ; white on black
    call printcs 

    mov si, bootMsgPt2
    mov bl, 0x0B ; cyan on black
    call printcs 

    mov si, bootMsgPt3
    mov bl, 0x03 ; dark'ish cyan on black
    call printcs 

    mov si, bootMsgPt4
    mov bl, 0x0F ; white on black
    call printcs 
    call printnl

    ; Load kernel from disk
    mov ah, 0x02 ; Read sectors from drive
    mov al, 16   ; Number of sectors to read
    mov ch, 0    ; Cylinder 0
    mov cl, 2    ; Sector 2 (1 is bootsector)
    mov dh, 0    ; Head 0
    mov dl, [bootdrive] ; Drive number from BIOS
    mov bx, 0x8000 ; Load address
    int 0x13

    jc .diskError ; Jump if error

    mov si, kernelLoadedMsg
    mov bl, 0x02
    call printcs

    jmp 0x0800:0x0000 ; Jump to kernel

.diskError:
    mov si, errorMsg
    mov bl, 0x04
    call printcs
    jmp $

bootdrive: db 0

bootMsgPt1: db "Booting ", 0
bootMsgPt2: db "Arc", 0
bootMsgPt3: db "OS", 0
bootMsgPt4: db "!", 0

errorMsg: db "Disk read error!", 0
kernelLoadedMsg: db "Kernel loaded.", 0

%include "core/output.s" ; provides printnl , prints, printcs , clears
%include "core/cursor.s" ; provides getcrsr , mvcrsr

times 510 - ($ - $$) db 0
dw 0xAA55
