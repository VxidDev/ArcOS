# Project Structure

```
ArcOS/
├── boot.s                    # Bootloader - BPB, FAT16 kernel loader
├── main.s                    # Kernel entry point, data definitions, %includes
├── makefile                  # Build system
├── README.md                 # Project overview
├── docs/
│   ├── building.md           # Build instructions and makefile details
│   ├── commands.md           # Shell command reference
│   ├── syscalls.md           # INT 0x80 syscall documentation
│   ├── programs.md           # Writing standalone programs
│   ├── memory.md             # Memory map and segment layout
│   ├── fat16.md              # FAT16 filesystem internals
│   └── internals.md          # Kernel-internal function reference
├── core/
│   ├── output.s              # Screen output (printc, prints, printcs, printnl, clears)
│   ├── cursor.s              # Cursor control (getcrsr, mvcrsr)
│   ├── input.s               # Keyboard input (getchar, getline, userInput)
│   ├── shell.s               # Shell loop, command parser (parseInput)
│   ├── shell_fat16.s         # Filesystem commands (ls, cat, touch, rm, mkdir, run)
│   ├── syscall.s             # INT 0x80 handler (output, input, filesystem, system)
│   ├── system.s              # Shutdown and reboot
│   ├── utils.s               # String/math utilities (atoi, itoa, memcmp_n, streq, strlen, strhex, sleep)
│   ├── disk.s                # INT 13h disk I/O (LBA reads/writes)
│   ├── fat16_bpb.s           # BPB parsing (reads FAT16 header from boot sector)
│   ├── fat16.s               # FAT16 init, cluster read/write, allocation
│   ├── fat16_dir.s           # Directory listing, search, 8.3 name conversion
│   └── fat16_file.s          # File read, write, create, delete, mkdir
└── progs/
    ├── calc.s                # Calculator (built-in shell command)
    ├── time.s                # Clock display (built-in)
    ├── tzconfig.s            # Timezone configuration (built-in)
    ├── sleep.s               # Sleep command (built-in)
    ├── bgconfig.s            # Background color configuration (built-in)
    ├── hello.s               # Example standalone program
    └── txtedit.s             # Text editor standalone program
```

## File Roles

### Boot (`boot.s`)

The bootloader occupies the first 512 bytes of the disk (the boot sector). It:
1. Reads the FAT16 BPB from the boot sector itself
2. Searches the root directory for `KERNEL.BIN`
3. Follows the FAT chain to load all clusters of the kernel into memory at `0x0800:0x0000`
4. Jumps to the kernel entry point

The BPB (bytes 0-61) provides filesystem geometry. The bootloader code (bytes 62-509) must fit in 448 bytes.

### Kernel (`main.s` + `core/`)

`main.s` is the kernel entry point. It:
1. Sets up segment registers (`DS = ES = SS = 0x0800`, `SP = 0xFFFF`)
2. Installs the `INT 0x80` syscall handler in the IVT
3. Clears the screen
4. Initializes the FAT16 filesystem
5. Prints the welcome message
6. Enters the shell loop

All `core/` files are `%include`d into `main.s` - they are not separate compilation units.

### Built-in Programs (`progs/`)

Files like `calc.s`, `time.s`, etc. are `%include`d into the kernel. They are called directly by the shell parser as subroutines (using `call`/`ret`). They have access to all kernel functions.

### Standalone Programs

Any `.s` file in `progs/` that is **not** `%include`d into `main.s` is built as a separate flat binary (`.bin`). These are loaded and executed via the `run` shell command. They can only use `INT 0x80` syscalls for I/O - they cannot call kernel functions directly.

### Text Editor (`progs/txtedit.s`)

A standalone text editor program that demonstrates file I/O via syscalls. Features:
- Prompts for a filename on startup
- Loads existing file contents via `sys_read_file` (0x06)
- Full-screen editing with cursor navigation
- Backspace with line wrapping
- **Ctrl+S** to save (writes via `sys_write_file` 0x05)
- **Ctrl+Q** to quit (returns to shell via `retf`)
