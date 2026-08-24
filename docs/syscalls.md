# Syscalls

ArcOS provides system calls via `INT 0x80`. Load the syscall number into `AH` and any parameters into the specified registers before calling.

## Output Syscalls

| Syscall | `AH` | Parameters | Description |
|---------|------|------------|-------------|
| `sys_print_char` | `0x00` | `AL` = character | Print a single character using BIOS teletype (INT 10h AH=0Eh). |
| `sys_print_string` | `0x01` | `SI` = null-terminated string | Print a string using INT 10h AH=09h with color `0x07 + currentBg`. |
| `sys_print_newline` | `0x02` | - | Move cursor to the start of the next line. Scrolls if at the bottom of the screen. |

## Input Syscalls

| Syscall | `AH` | Parameters | Returns | Description |
|---------|------|------------|---------|-------------|
| `sys_getchar` | `0x10` | - | `AL` = ASCII character | Blocking keyboard read. Waits for a keypress and returns the ASCII value. |

## System Syscalls

| Syscall | `AH` | Parameters | Description |
|---------|------|------------|-------------|
| `sys_shutdown` | `0xA0` | - | Shutdown via APM (INT 15h). Falls back to QEMU virtual power-off (port 0x604). |
| `sys_reboot` | `0xA1` | - | Reboot via keyboard controller reset (port 0x64, command 0xFE). |

## Usage Example

```asm
; Print a string
mov ah, 0x01
mov si, my_string
int 0x80

; Print a newline
mov ah, 0x02
int 0x80

; Read a character
mov ah, 0x10
int 0x80
; AL now contains the pressed key

my_string: db "Hello, ArcOS!", 0
```

## Register Preservation

All syscalls use `pusha`/`popa` internally, so general-purpose registers are preserved across the `INT 0x80` call. The flags register is modified by `iret`.
