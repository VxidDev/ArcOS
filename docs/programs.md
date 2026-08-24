# Writing Programs

Standalone programs are flat binary executables assembled with NASM. They are loaded into memory at segment `0x0900` (physical address `0x9000`) and executed by the `run` command.

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

1. **Start with `[org 0x0000]`** - programs are loaded at offset 0 within segment `0x0900`.
2. **Put code first** - execution starts at offset 0. Do not put data or use `section .data` before your code.
3. **Return with `retf`** - this is a far return that pops the return address pushed by `call 0x0900:0x0000` and returns control to the shell.
4. **Use INT 0x80 syscalls** for I/O. Do not use BIOS interrupts directly - the kernel's IVT entries may differ from the standard BIOS layout.
5. **Preserve segment registers** - the kernel expects `DS = ES = 0x0800` when your program returns. If you modify them, restore before `retf`.

## Environment

| Register | Value | Notes |
|----------|-------|-------|
| `CS` | `0x0900` | Code segment |
| `DS` | `0x0900` | Data segment (set by kernel before call) |
| `ES` | `0x0900` | Extra segment (set by kernel before call) |
| `SS` | `0x0900` | Stack segment |
| `SP` | `0x8000` | Stack pointer (within the program's segment) |

The program's memory spans from `0x0900:0x0000` to `0x0900:0x7FFF` (up to 32 KB).

## Available Syscalls

See [syscalls.md](syscalls.md) for the full list. The most commonly used:

| `AH` | Function | Example |
|------|----------|---------|
| `0x00` | Print character | `mov al, 'A'` / `mov ah, 0x00` / `int 0x80` |
| `0x01` | Print string | `mov si, msg` / `mov ah, 0x01` / `int 0x80` |
| `0x02` | Print newline | `mov ah, 0x02` / `int 0x80` |
| `0x10` | Read character | `mov ah, 0x10` / `int 0x80` - result in `AL` |

## Building

1. Create a file in `progs/`, e.g. `progs/myprog.s`
2. Run `make`
3. The binary is automatically built as `progs/myprog.bin` and copied to the disk image as `MYPROG.BIN`
4. In the shell, type `run MYPROG.BIN`

The makefile automatically discovers any `.s` files in `progs/`. Programs that are `%include`d into the kernel (like `calc.s`, `time.s`) are excluded from standalone builds.

## Complete Example: Echo Program

```asm
[org 0x0000]

; Print prompt
mov ah, 0x01
mov si, prompt
int 0x80

; Read a character
mov ah, 0x10
int 0x80
; AL = pressed key

; Echo it back
mov ah, 0x00
int 0x80

; Newline
mov ah, 0x02
int 0x80

retf

prompt: db "Press a key: ", 0
```
