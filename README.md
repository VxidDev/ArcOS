# ArcOS

**ArcOS** is a lightweight, 16-bit command-line operating system written entirely in x86 assembly for the IBM PC and compatible systems. 

## Features

*   **16-bit Bootloader:** Boots directly from a floppy or hard disk image.
*   **Interactive Shell:** A simple command-line interface for user interaction.
*   **Syscall-based API:** A basic set of system calls for core functionalities.
*   **Built-in Commands:** Includes essential commands like `echo`, `clear`, `color`, `shutdown`, `reboot`, and `calc` (a simple calculator).

## License

ArcOS is licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).

## Getting Started

To build and run ArcOS, you will need `nasm` and `qemu`.

### Building

Use the provided `makefile` to build the ArcOS image:

```bash
make
```

### Running

To run ArcOS in QEMU:

```bash
make run
```

## Syscall Documentation

ArcOS provides a set of system calls to interact with the operating system. To invoke a syscall, load the syscall number into the `ah` register and call `int 0x80`.

| Syscall | `ah` | Description | Parameters |
|---|---|---|---|
| `sys_print_char` | `0x00` | Prints a single character to the screen. | `al` = The character to print. |
| `sys_print_string` | `0x01` | Prints a null-terminated string to the screen. | `si` = Pointer to the string. |
| `sys_print_newline` | `0x02` | Prints a newline character. | None. |
| `sys_getchar` | `0x10` | Reads a single character from the keyboard. | None. |
| `sys_shutdown` | `0xA0` | Shuts down the system. | None. |
| `sys_reboot` | `0xA1` | Reboots the system. | None. |

## Adding a Shell Command

To add a new command to the ArcOS shell, you need to modify `main.s` and `core/shell.s`. Here's a step-by-step guide:

1.  **Declare the command string in `main.s`:**
    Add a new `db` directive with your command name and a corresponding `equ` for its length.

    ```assembly
    ; in main.s
    my_command: db "mycmd", 0
    my_commandLen equ $ - my_command
    ```

2.  **Add the command parsing logic in `core/shell.s`:**
    In `parseInput`, add a new section to check for your command. You can follow the pattern of the existing commands.

    ```assembly
    ; in core/shell.s, within parseInput, after the last command
    .skipReboot: ; or the label of the last command check

    xor bx, bx
    mov si, my_command

    .myCommandLoop:
        cmp bx, my_commandLen
        je .execMyCommand

        cmp [inputBuf + bx], 0
        je .skipMyCommand

        mov al, [si + bx]
        cmp al, [inputBuf + bx]
        jne .skipMyCommand

        inc bx
        jmp .myCommandLoop

    .execMyCommand:
        ; Your command's logic goes here
        ; For example, to print a message:
        mov si, my_message
        mov bl, 0x0F
        call printcs
        call printnl
        ret

    .skipMyCommand:
        ; This label is where the next command check would start,
        ; or the "command not found" message if this is the last one.
    ```

3.  **Add any required data:**
    If your command needs to print a message, add the string to `main.s`:

    ```assembly
    ; in main.s
    my_message: db "This is my new command!", 0
    ```

## File Structure

The project is organized into the following files:

*   `boot.s`: The bootloader.
*   `main.s`: The main kernel file, containing the entry point and the main shell loop.
*   `makefile`: The build script for NASM.
*   `core/`: A directory for the core components of the OS.
    *   `cursor.s`: Functions for cursor manipulation.
    *   `input.s`: Keyboard input functions.
    *   `output.s`: Screen output functions.
    *   `shell.s`: The shell and command parser.
    *   `syscall.s`: The system call handler.
    *   `system.s`: System-level functions like shutdown and reboot.
    *   `utils.s`: Utility functions.
*   `progs/`: A directory for user programs.
    *   `calc.s`: A simple calculator program implemented as a shell command.
