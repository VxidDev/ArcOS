# ArcOS

A lightweight, 16-bit command-line operating system written in x86 assembly (NASM) for IBM PC compatibles.

## Features

- **16-bit Bootloader** - boots from a FAT16 disk image
- **Interactive Shell** - built-in commands for file management, calculator, clock, and more
- **FAT16 Filesystem** - create, read, delete files and directories
- **Syscall API** - INT 0x80 interface for I/O and system control
- **Standalone Programs** - load and run `.BIN` programs from disk

## Quick Start

Requires: `nasm`, `qemu`, `mtools`

```bash
make        # build ArcOS.bin
make run    # build and run in QEMU
```

## Documentation

| Doc | Description |
|-----|-------------|
| [Building](docs/building.md) | Build instructions, makefile details, output format |
| [Shell Commands](docs/commands.md) | All built-in and filesystem commands |
| [Syscalls](docs/syscalls.md) | INT 0x80 system call reference |
| [Writing Programs](docs/programs.md) | How to write standalone programs for `run` |
| [Memory Layout](docs/memory.md) | Memory map, segment layout, boot sector structure |
| [Internal API](docs/internals.md) | Kernel functions available to built-in commands |
| [FAT16 Filesystem](docs/fat16.md) | Disk layout, cluster chains, directory entries, how files work |

## License

[GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html)
