# Building

## Requirements

- **nasm** - Netwide Assembler (flat binary output)
- **qemu-system-x86_64** - for running the OS
- **mtools** - for `mcopy` (manipulating FAT16 disk images)
- **GNU Make** - build automation

On Debian/Ubuntu:
```bash
sudo apt install nasm qemu-system-x86 mtools make
```

## Build Commands

```bash
make          # build ArcOS.bin
make run      # build and launch in QEMU
make clean    # remove all build artifacts
```

## What Happens During Build

1. **`boot.bin`** - `boot.s` is assembled as a 512-byte flat binary (boot sector).
2. **`kernel.bin`** - `main.s` is assembled, pulling in all `%include`d source files from `core/` and `progs/`.
3. **`progs/*.bin`** - Any `.s` files in `progs/` that are not `%include`d into the kernel are assembled as standalone flat binaries.
4. **`ArcOS.bin`** - A raw disk image is created:
   - 4 MB zeroed image
   - Formatted as FAT16 (1 sector/cluster, 224 root entries, 512 byte sectors)
   - `KERNEL.BIN` and all `*.BIN` programs are copied to the root directory
   - The boot sector is written at byte offset 62 (the BPB occupies the first 62 bytes)

## Output

The final output is `ArcOS.bin`, a raw disk image that can be:
- Run directly in QEMU: `qemu-system-x86_64 -drive file=ArcOS.bin,format=raw,if=ide`
- Written to a floppy/USB: `dd if=ArcOS.bin of=/dev/sdX bs=512`

## Makefile Details

The makefile auto-discovers standalone programs:

```makefile
BUILTIN_PROGS = calc time tzconfig sleep bgconfig
PROGRAMS = $(filter-out ..., $(patsubst progs/%.s,progs/%.bin, $(wildcard progs/*.s)))
```

Programs listed in `BUILTIN_PROGS` are excluded from standalone builds because they are `%include`d into the kernel as built-in shell commands. Any new `.s` file added to `progs/` (not in that list) will be automatically built and included in the disk image.
