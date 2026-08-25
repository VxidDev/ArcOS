# Syscalls

ArcOS provides system calls via `INT 0x80`. Load the syscall number into `AH` and any parameters into the specified registers before calling.

## Output Syscalls

| Syscall | `AH` | Parameters | Description |
|---------|------|------------|-------------|
| `sys_print_char` | `0x00` | `AL` = character | Print a single character using BIOS teletype (INT 10h AH=0Eh). |
| `sys_print_string` | `0x01` | `SI` = null-terminated string | Print a string using INT 10h AH=09h with color `0x07 + currentBg`. |
| `sys_print_newline` | `0x02` | - | Move cursor to the start of the next line. Scrolls if at the bottom of the screen. |
| `sys_clear` | `0x03` | - | Clear the entire screen and reset cursor to top-left. |
| `sys_print_colored_string` | `0x04` | `SI` = null-terminated string, `BL` = color attribute | Print a string with the specified color attribute. |

## Filesystem Syscalls

| Syscall | `AH` | Parameters | Returns | Description |
|---------|------|------------|---------|-------------|
| `sys_write_file` | `0x05` | `SI` = filename (null-terminated), `BX` = buffer, `CX` = byte count | `[0x5000]` = bytes written (0 = fail) | Write data from a buffer to a file. Creates the file if it doesn't exist; overwrites if it does. |
| `sys_read_file` | `0x06` | `SI` = filename (null-terminated), `BX` = buffer, `CX` = max bytes | `[0x5000]` = bytes read (0 = not found/fail) | Read a file from disk into a buffer. |

## Input Syscalls

| Syscall | `AH` | Parameters | Returns | Description |
|---------|------|------------|---------|-------------|
| `sys_getchar` | `0x10` | - | `AL` = ASCII character | Blocking keyboard read. Waits for a keypress and returns the ASCII value. |
| `sys_get_cursor` | `0x11` | - | `DH` = row, `DL` = column | Get the current cursor position. Values also stored at `[0x5000]` (row) and `[0x5001]` (column). |
| `sys_move_cursor` | `0x12` | `DH` = row, `DL` = column | - | Move the cursor to the specified position. |
| `sys_get_line` | `0x14` | `SI` = buffer, `BX` = max length | `AX` = bytes read | Read a line of input with backspace editing. Null-terminates the result. |

## System Syscalls

| Syscall | `AH` | Parameters | Description |
|---------|------|------------|-------------|
| `sys_shutdown` | `0xA0` | - | Shutdown via APM (INT 15h). Falls back to QEMU virtual power-off (port 0x604). |
| `sys_reboot` | `0xA1` | - | Reboot via keyboard controller reset (port 0x64, command 0xFE). |

## Return Values

Disk and input syscalls return values through a shared memory location at `DS:0x5000`. For user programs, `DS` points to the program's own segment, so `[0x5000]` is accessible directly:

```asm
mov ah, 0x06          ; sys_read_file
mov si, filename
mov bx, buffer
mov cx, 4096
int 0x80

; AX is NOT the return value — popa restores it.
; Read the actual return value from [0x5000]:
mov ax, [0x5000]      ; bytes read
```

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

; Write a file
mov ah, 0x05
mov si, filename
mov bx, data_buffer
mov cx, 100           ; 100 bytes
int 0x80

; Clear screen
mov ah, 0x03
int 0x80

my_string: db "Hello, ArcOS!", 0
filename: db "MYFILE.TXT", 0
```

## Register Preservation

All syscalls use `pusha`/`popa` internally, so general-purpose registers are preserved across the `INT 0x80` call. Segment registers `DS` and `ES` are also saved and restored. The flags register is modified by `iret`.
