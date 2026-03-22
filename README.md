# ArcOS

**ArcOS** is a lightweight, 16-bit command-line operating system written entirely in x86 assembly for the IBM PC and compatible systems. 

## Features

*   **16-bit Bootloader:** Boots directly from a floppy or hard disk image.
*   **Interactive Shell:** A simple command-line interface for user interaction.
*   **Syscall-based API:** A basic set of system calls for core functionalities.
*   **Built-in Commands:** Includes essential commands like `echo`, `clear`, `color`, `shutdown`, `reboot`, and the following programs:
    *   `calc`: A simple calculator.
    *   `time`: A program to get the current time.
    *   `tzconfig`: A program to configure the time zone.

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

Adding a new command to the ArcOS shell involves creating a new program file and integrating it with the existing shell. Here is a step-by-step guide:

1.  **Create your program file in `progs/`:**
    Create a new assembly file in the `progs/` directory (e.g., `my_program.s`). This file will contain the logic for your command. The entry point of your program should be a label (e.g., `my_program:`).

    ```assembly
    ; in progs/my_program.s
    my_program:
        ; Your command's logic goes here.
        ; For example, to print a message:
        mov si, my_message
        mov bl, 0x0F
        call printcs
        call printnl
        ret

    my_message: db "This is my new program!", 0
    ```

2.  **Declare the command string and include your program in `main.s`:**
    In `main.s`, add a `db` directive for your command name and an `equ` for its length. Also, include your new program file using `%include`.

    ```assembly
    ; in main.s

    ; ... other command definitions
    myProgramCmd: db "myprog", 0
    myProgramCmdLen equ $ - myProgramCmd

    ; ... other includes
    %include "progs/my_program.s"
    ```

3.  **Add the command parsing logic in `core/shell.s`:**
    In the `parseInput` function in `core/shell.s`, add a new section to check for your command and call its entry point.

    ```assembly
    ; in core/shell.s, within parseInput, before the "command not found" part

    ; ... after the last command check
    .skipTz: ; or the label of the last command check

    mov si, myProgramCmd
    mov di, inputBuf
    mov bx, myProgramCmdLen

    call memcmp_n

    cmp al, 0
    je .skipMyProgram

    .execMyProgram:
        ; check for arguments, etc.
        call my_program
        ret

    .skipMyProgram:
        ; This label is where the next command check would start,
        ; or the "command not found" message if this is the last one.
    ```

## File Structure

The project is organized into the following files:

*   `boot.s`: The bootloader.
*   `main.s`: The main kernel file, containing the entry point and the main shell loop.
*   `makefile`: The build script for NASM.
*   `README.md`: This file.
*   `calc.md`, `time.md`, `tzconfig.md`: Documentation for the programs.
*   `core/`: A directory for the core components of the OS.
    *   `cursor.s`: Functions for cursor manipulation.
    *   `input.s`: Keyboard input functions.
    *   `output.s`: Screen output functions.
    *   `shell.s`: The shell and command parser.
    *   `syscall.s`: The system call handler.
    *   `system.s`: System-level functions like shutdown and reboot.
    *   `utils.s`: Utility functions.
*   `progs/`: A directory for user programs.
    *   `calc.s`: A simple calculator program.
    *   `time.s`: A program to get the current time.
    *   `tzconfig.s`: A program to configure the time zone.
