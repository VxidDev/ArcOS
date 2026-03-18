[org 0x0000]
[bits 16]

global kernel_main

kernel_main:
    cli ; disable interrupts

    mov ax, 0x0800
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x8000 

    sti ; enable interrupts

    call clears

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

    call printnl
    call printnl

.shell:
    mov si, prompt
    mov bl, 0x0B 
    call printcs

    call userInput
    call printnl
    call parseInput 

    jmp .shell

%include "core/output.s" 
%include "core/cursor.s"
%include "core/input.s"  
%include "core/shell.s" 
%include "core/utils.s"
%include "core/system.s"

prompt: db "ArcOS > ", 0
promptLen equ $ - prompt

inputBuf: times 32 db 0

echo: db "echo"
echoLen equ $ - echo

clear: db "clear"
clearLen equ $ - clear

color: db "color"
colorLen equ $ - color

currColor: db 0x07

shutdown: db "shutdown"
shutdownLen equ $ - shutdown

commandNotFound: db "Command not found!", 0

greetingPt1: db "Welcome to ", 0
greetingPt2: db "Arc", 0
greetingPt3: db "OS", 0
greetingPt4: db "!", 0
