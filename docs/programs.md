# Writing Programs

Standalone programs are flat binary executables assembled with NASM. They are loaded into memory at segment `0x0E00` (physical address `0xE000`) and executed by the `run` command.

## Program Template

```asm
[org 0x0000]

; --- your code here ---
mov ah, 0x01          ; sys_print_string
mov si, msg
int 0x80

mov ah, 0x02          ; sys_print_newline
int 0x80

retf                  ; return to the shell

msg: db "Hello from my program!", 0
```

## Rules

1. **Start with `[org 0x0000]`** - programs are loaded at offset 0 within segment `0x0E00`.
2. **Put code first** - execution starts at offset 0. Do not put data or use `section .data` before your code.
3. **Return with `retf`** - this is a far return that pops the return address pushed by `call 0x0E00:0x0000` and returns control to the shell.
4. **Use INT 0x80 syscalls** for I/O. Do not use BIOS interrupts directly - the kernel's IVT entries may differ from the standard BIOS layout.
5. **Preserve segment registers** - the kernel expects `DS = ES = 0x0800` when your program returns. If you modify them, restore before `retf`.
6. **Do not modify SS or SP** - the stack is in kernel memory space. Modifying SS/SP will corrupt the kernel stack and crash.

## Environment

| Register | Value | Notes |
|----------|-------|-------|
| `CS` | `0x0E00` | Code segment |
| `DS` | `0x0E00` | Data segment (set by kernel before call) |
| `ES` | `0x0E00` | Extra segment (set by kernel before call) |
| `SS` | `0x0800` | Stack segment (kernel segment, shared with kernel stack) |
| `SP` | ~`0x8000` | Stack pointer (kernel stack area, grows downward) |

The program's code/data spans from `0x0E00:0x0000` to ~`0x0E00:0x5FFF` (up to ~24 KB). The stack is in kernel space at `0x0800:0x8000` (physical `0x10000`), so programs share the kernel's stack. Maximum safe program size is ~8 KB to avoid overlapping the stack.

## Memory Layout

```
0x0E00:0x0000 ┌──────────────────────────┐
              │  Program code + data     │  Up to ~8 KB
              │                          │
0x0E00:0x2000 ├──────────────────────────┤
              │  (free space)            │
              │                          │
0x0800:0x8000 ├──────────────────────────┤
              │  Kernel stack            │  Grows downward (shared)
              │  (physical 0x10000)      │
```

## Available Syscalls

See [syscalls.md](syscalls.md) for the full list. The most commonly used:

| `AH` | Function | Parameters | Returns |
|------|----------|------------|---------|
| `0x00` | Print character | `AL` = char | - |
| `0x01` | Print string | `SI` = string | - |
| `0x02` | Print newline | - | - |
| `0x03` | Clear screen | - | - |
| `0x04` | Print colored string | `SI` = string, `BL` = color | - |
| `0x05` | Write file | `SI` = filename, `BX` = buffer, `CX` = bytes | `[0x5000]` = written |
| `0x06` | Read file | `SI` = filename, `BX` = buffer, `CX` = max bytes | `[0x5000]` = read |
| `0x10` | Read character | - | `AL` = key |
| `0x11` | Get cursor | - | `[0x5000]` = row, `[0x5001]` = col |
| `0x12` | Move cursor | `DH` = row, `DL` = col | - |
| `0x14` | Get line | `SI` = buffer, `BX` = max len | `AX` = bytes read |

**Note:** Return values are stored at `[0x5000]`, not in registers. After `int 0x80`, general-purpose registers (including `AX`) are restored to their pre-syscall values by `popa`.

## Building

1. Create a file in `progs/`, e.g. `progs/myprog.s`
2. Run `make`
3. The binary is automatically built as `progs/myprog.bin` and copied to the disk image as `MYPROG.BIN`
4. In the shell, type `run MYPROG.BIN`

The makefile automatically discovers any `.s` files in `progs/`. Programs that are `%include`d into the kernel (like `calc.s`, `time.s`) are excluded from standalone builds.

## Complete Example: File Reader

```asm
[org 0x0000]

; Prompt for filename
mov ah, 0x04
mov si, prompt
mov bl, 0x0B
int 0x80

; Read filename from user
mov ah, 0x14
mov si, fname_buf
mov bx, 12
int 0x80

; Clear screen
mov ah, 0x03
int 0x80

; Read file
mov ah, 0x06
mov si, fname_buf
mov bx, read_buf
mov cx, 512
int 0x80

; Print file contents
mov ah, 0x01
mov si, read_buf
int 0x80

; Newline
mov ah, 0x02
int 0x80

retf

prompt: db "File: ", 0
fname_buf: times 12 db 0
read_buf: times 512 db 0
```

## Complete Example: File Writer

```asm
[org 0x0000]

; Write "Hello" to FILE.TXT
mov ah, 0x05
mov si, filename
mov bx, data
mov cx, 5            ; 5 bytes
int 0x80

; Check result
mov ax, [0x5000]     ; bytes written

retf

filename: db "FILE.TXT", 0
data: db "Hello"
```
