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
        │  Kernel                  │  Code, data, BSS, stack
        │  0x0800:0x0000           │
        │                          │  Code + data
        │         ...              │
        │                          │  Stack (grows down from 0x8000)
0x10000 ├──────────────────────────┤
        │  User program space      │  32 KB
        │  0x0900:0x0000           │  Loaded by `run` command
        │                          │
0x18000 ├──────────────────────────┤
        │  Free                    │
        │                          │
```

## Key Addresses

| Physical Address | Segment:Offset | Size | Contents |
|-----------------|----------------|------|----------|
| `0x00000` | `0x0000:0x0000` | 1 KB | Interrupt Vector Table |
| `0x00400` | `0x0040:0x0000` | 256 B | BIOS Data Area |
| `0x7C00` | `0x0000:0x7C00` | 512 B | Bootloader (loaded by BIOS) |
| `0x7E00` | `0x0000:0x7E00` | 512 B | Disk read buffer (boot sector) |
| `0x8000` | `0x0800:0x0000` | ~23 KB | Kernel code + data |
| `0x9000` | `0x0900:0x0000` | 32 KB | User programs (loaded by `run`) |

## Kernel Memory

The kernel is loaded at `0x0800:0x0000` (physical `0x8000`).

- **Code and data** occupy approximately 23 KB (kernel binary size).
- **Stack** grows downward from `0x0800:0x8000` (physical `0x10000`).
- The kernel binary must not exceed ~31 KB to avoid colliding with the stack.

## User Program Space

Programs loaded by the `run` command are placed at `0x0900:0x0000` (physical `0x9000`).

- Programs run with `CS = DS = ES = SS = 0x0900`.
- Stack starts at `SP = 0x8000` (physical `0x11000`), giving 32 KB of stack space.
- Maximum program size: ~32 KB (limited by the segment boundary at `0x0A000`).

## Boot Sector Layout

The boot sector is exactly 512 bytes:

| Offset | Size | Contents |
|--------|------|----------|
| `0x00-0x02` | 3 B | Jump instruction |
| `0x03-0x0A` | 8 B | OEM identifier |
| `0x0B-0x3D` | 59 B | BIOS Parameter Block (FAT16 BPB) |
| `0x3E-0x1FD` | 448 B | Bootloader code and data |
| `0x1FE-0x1FF` | 2 B | Boot signature (`0x55AA`) |
