# Memory Layout

ArcOS runs in 16-bit real mode. All addresses are segment:offset pairs (physical = segment * 16 + offset).

## Memory Map

```
0x00000 ┌──────────────────────────┐
        │  IVT                     │  Interrupt Vector Table (1 KB)
        │  256 entries × 4 bytes   │  INT 0x00 through INT 0xFF
0x00400 ├──────────────────────────┤
        │  BIOS Data Area (BDA)    │  Keyboard buffer, cursor position,
        │                          │  equipment list, etc.
0x00500 ├──────────────────────────┤
        │                          │
        │  Free / Available        │
        │                          │
0x7C00  ├──────────────────────────┤
        │  Bootloader              │  512 bytes (BPB + code)
        │  0x0000:0x7C00           │  Loaded by BIOS
0x7E00  ├──────────────────────────┤
        │  Boot read buffer        │  512 bytes (FAT sectors, root dir)
0x8000  ├──────────────────────────┤
        │  Kernel                  │  Code, data, BSS (~64 KB segment)
        │  0x0800:0x0000           │
        │         ...              │
0x17FFF  ├──────────────────────────┤
        │  Kernel stack            │  Grows downward from SP=0xFFFF
        │  0x0800:0xFFFF           │
0x28000 ├──────────────────────────┤
        │  User programs           │  Loaded by `run` command
        │  0x2800:0x0000           │  (~24 KB available)
        │         ...              │
```

## Key Addresses

| Physical Address | Segment:Offset | Size | Contents |
|-----------------|----------------|------|----------|
| `0x00000` | `0x0000:0x0000` | 1 KB | Interrupt Vector Table |
| `0x00400` | `0x0040:0x0000` | 256 B | BIOS Data Area |
| `0x7C00` | `0x0000:0x7C00` | 512 B | Bootloader (loaded by BIOS) |
| `0x7E00` | `0x0000:0x7E00` | 512 B | Disk read buffer (boot sector) |
| `0x8000` | `0x0800:0x0000` | ~64 KB | Kernel code + data |
| `0x17FFF` | `0x0800:0xFFFF` | - | Kernel stack top (grows downward) |
| `0x28000` | `0x2800:0x0000` | ~24 KB | User programs (loaded by `run`) |

## Kernel Memory

The kernel is loaded at `0x0800:0x0000` (physical `0x8000`).

- **Code and data** occupy approximately 2-3 KB (kernel binary size).
- **Available space** extends to ~128 KB, providing room for buffers, FAT cache, and future growth.
- **Stack** grows downward from `0x0800:0xFFFF` (physical `0x17FFF`).

## User Program Space

Programs loaded by the `run` command are placed at `0x2800:0x0000` (physical `0x28000`).

- Programs run with `CS = DS = ES = 0x2800`. `SS` remains `0x0800` (kernel segment).
- The stack is in kernel space — programs share the kernel's stack.
- Maximum program size: ~24 KB (limited by the gap between the user load address and the kernel stack).
- Programs are loaded by `cmd_run`, which reads the file via `fat16_file_read` with `ES=0x2800`.

## Boot Sector Layout

The boot sector is exactly 512 bytes:

| Offset | Size | Contents |
|--------|------|----------|
| `0x00-0x02` | 3 B | Jump instruction |
| `0x03-0x0A` | 8 B | OEM identifier |
| `0x0B-0x3D` | 59 B | BIOS Parameter Block (FAT16 BPB) |
| `0x3E-0x1FD` | 448 B | Bootloader code and data |
| `0x1FE-0x1FF` | 2 B | Boot signature (`0x55AA`) |
