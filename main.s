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

    xor ax, ax
    mov ds, ax

    mov word [0x80 * 4], syscallHandler
    mov word [0x80 * 4 + 2], cs

    mov ax, 0x0800
    mov ds, ax

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

    mov si, inputBuf

    call userInput
    call printnl
    call parseInput 

    jmp .shell

%include "core/output.s" ; provides prints, printc, printcs, printnl, clears 
%include "core/cursor.s" ; provides mvcrsr, getcrsr
%include "core/input.s"  ; provides getchar 
%include "core/shell.s"  ; provides userInput, parseInput
%include "core/utils.s"  ; provides strhex , atoi , itoa
%include "core/system.s" ; provides shtdwn 
%include "core/syscall.s" ; provides syscallHandler

; removing this breaks parseInput
%include "progs/calc.s" ; provides calc
%include "progs/time.s" ; provides time
%include "progs/tzconfig.s" ; provides tzconfig

itoa_isNeg: db 0

calc_firstNum: dw 0
calc_secondNum: dw 0
calc_operator: db 0
calc_unknownOper: db "calc: Unknown operation!", 0
calc_itoaBuf: times 8 db 0 ; buffer for 6 characters, null-byte and additional byte for safety.
calc_invNum: db "calc: invalid number!", 0
calc_divByZero: db "calc: division by zero is not allowed.", 0

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

reboot: db "reboot"
rebootLen equ $ - reboot

calcCmd: db "calc"
calcLen equ $ - calcCmd

timeCmd: db "time"
timeLen equ $ - timeCmd

time_hours: dw 0
time_minutes: dw 0
time_seconds: dw 0
time_hoursItoaBuf: times 5 db 0
time_minutesItoaBuf: times 5 db 0
time_secondsItoaBuf: times 5 db 0 
time_separator: db ':', 0
time_zero: db '0', 0, 0 ; additional byte for safety

tzCmd: db "tzconfig"
tzCmdLen equ $ - tzCmd

tz_invOffset: db "tzconfig: invalid offset!", 0
tz_offset: db 0

commandNotFound: db "Command not found!", 0

greetingPt1: db "Welcome to ", 0
greetingPt2: db "Arc", 0
greetingPt3: db "OS", 0
greetingPt4: db "!", 0
