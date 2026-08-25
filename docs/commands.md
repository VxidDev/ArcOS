# Shell Commands

## Built-in Commands

### echo

```
echo <text>
```

Print the given text to the screen, followed by a newline.

### clear

```
clear
```

Clear the entire screen and move the cursor to the top-left corner.

### color

```
color <hex>
```

Set the foreground text color. The argument is a single hex digit (0-F).

| Value | Color |
|-------|-------|
| 0 | Black |
| 1 | Blue |
| 2 | Green |
| 3 | Cyan |
| 4 | Red |
| 5 | Magenta |
| 6 | Brown |
| 7 | Light Gray |
| 8 | Dark Gray |
| 9 | Light Blue |
| A | Light Green |
| B | Light Cyan |
| C | Light Red |
| D | Light Magenta |
| E | Yellow |
| F | White |

Running `color` without arguments resets to the default (0x07, light gray).

### bgconfig

```
bgconfig <0-15>
```

Set the background color for the entire screen. Accepts a decimal value from 0 to 15. The screen is cleared after changing.

Running `bgconfig` without arguments resets to black (0) and clears the screen.

### time

```
time
```

Display the current system time in `HH:MM:SS` format (24-hour, no timezone adjustment).

### tzconfig

```
tzconfig <offset>
```

Set a timezone offset in hours (added to the raw time value). Accepts positive and negative integers.

Running `tzconfig` without arguments resets the offset to 0 (UTC).

### calc

```
calc <number> <operator> <number>
```

A simple integer calculator.

**Operators:**
| Operator | Operation |
|----------|-----------|
| `+` | Addition |
| `-` | Subtraction |
| `*` | Multiplication |
| `/` | Division (truncates toward zero) |

**Examples:**
```
calc 10 + 5
calc 100 - 37
calc 6 * 7
calc 20 / 3
```

**Errors:** Division by zero and invalid input produce error messages.

### sleep

```
sleep <seconds>
```

Pause execution for the given number of seconds (approximate, based on the 18.2 Hz BIOS timer tick).

---

## Filesystem Commands

### ls

```
ls
```

List all files and directories in the current directory. Shows filenames in 8.3 format, file sizes, and entry types.

### cat

```
cat <filename>
```

Print the contents of a file to the screen. The file must exist in the current directory.

### touch

```
touch <filename>
```

Create a new, empty file. Fails if the file already exists.

### rm

```
rm <filename>
```

Delete a file from the current directory. Fails if the file is not found.

### mkdir

```
mkdir <name>
```

Create a new directory. The name is converted to 8.3 format.

---

## Program Execution

### run

```
run <FILENAME.BIN>
```

Load a flat binary file from the FAT16 filesystem and execute it. The file is loaded into memory at segment `0x0E00` (physical address `0xE000`). The program runs with `CS = DS = ES = SS = 0x0E00`.

Programs must return to the shell with `retf`.

See [programs.md](programs.md) for how to write standalone programs.
