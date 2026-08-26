[org 0x0000]
[bits 16]

global kernel_main

kernel_main:
    cli ; disable interrupts

    mov ax, 0x0800
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFF

    mov [kernel_bootdrive], dl ; save boot drive from BIOS

    mov ax, 0x0000
    mov ds, ax

    mov word [0x80 * 4], syscallHandler
    mov word [0x80 * 4 + 2], cs

    mov ax, 0x0800
    mov ds, ax

    sti ; enable interrupts

    call clears

    call fat16_init

    mov si, greetingPt1
    mov bl, 0x0F
    add bl, [currentBg]
    call printcs

    mov si, greetingPt2
    mov bl, 0x0B
    add bl, [currentBg]
    call printcs 

    mov si, greetingPt3
    mov bl, 0x03
    add bl, [currentBg]
    call printcs 

    mov si, greetingPt4 
    mov bl, 0x0F
    add bl, [currentBg]
    call printcs

    call printnl
    call printnl

    .shell:
        mov si, prompt
        mov bl, 0x0B
        add bl, [currentBg] 
        call printcs

        mov si, inputBuf

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
%include "core/syscall.s"
%include "core/disk.s"
%include "core/fat16_bpb.s"
%include "core/fat16.s"
%include "core/fat16_dir.s"
%include "core/fat16_file.s"
%include "core/shell_fat16.s"

; removing this breaks parseInput
%include "progs/calc.s"
%include "progs/time.s"
%include "progs/tzconfig.s"
%include "progs/sleep.s"
%include "progs/bgconfig.s"
%include "progs/as16.s"

kernel_bootdrive: db 0

itoa_isNeg: db 0
itoa_buf: times 8 db 0

calc_firstNum: dw 0
calc_secondNum: dw 0
calc_operator: db 0
calc_unknownOper: db "calc: Unknown operation!", 0
calc_itoaBuf: times 8 db 0
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
time_zero: db '0', 0, 0

tzCmd: db "tzconfig"
tzCmdLen equ $ - tzCmd

tz_invOffset: db "tzconfig: invalid offset!", 0
tz_offset: db 0

commandNotFound: db "Command not found!", 0

greetingPt1: db "Welcome to ", 0
greetingPt2: db "Arc", 0
greetingPt3: db "OS", 0
greetingPt4: db "!", 0

lsCmd: db "ls"
lsCmdLen equ $ - lsCmd

catCmd: db "cat"
catCmdLen equ $ - catCmd

touchCmd: db "touch"
touchCmdLen equ $ - touchCmd

rmCmd: db "rm"
rmCmdLen equ $ - rmCmd

mkdirCmd: db "mkdir"
mkdirCmdLen equ $ - mkdirCmd

runCmd: db "run"
runCmdLen equ $ - runCmd

as16Cmd: db "as16"
as16CmdLen equ $ - as16Cmd

bpb_buffer: times 512 db 0
bpb_sectors_per_cluster: db 0
bpb_reserved_sectors: dw 0
bpb_num_fats_copy: db 0
bpb_max_root_entries: dw 0
bpb_total_sectors: dw 0
bpb_sectors_per_fat: dw 0
bpb_sectors_per_track: dw 0
bpb_num_heads: dw 0

fat_start: dw 0
root_dir_start: dw 0
data_start: dw 0
fat_buffer: times 16384 db 0
sector_buffer: times 512 db 0
cluster_buffer: times 512 db 0

syscall_user_ds: dw 0
current_dir_cluster: dw 0
current_path: times 32 db 0
dir_marker: db "<DIR>", 0
space_str: db " ", 0
temp_name: times 13 db 0
