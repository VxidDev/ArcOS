# Internal API Reference

Reference for kernel-internal functions. These are callable from code that is `%include`d into the kernel (built-in shell commands). They are **not** available to standalone programs loaded via `run` - those must use INT 0x80 syscalls.

## Output (`core/output.s`)

| Function | Usage | Description |
|----------|-------|-------------|
| `printc` | `AL` = character | Print a single character via BIOS teletype (INT 10h AH=0Eh). |
| `prints` | `SI` = null-terminated string | Print a string with color `0x07 + currentBg`. Uses INT 10h AH=09h with cursor management. |
| `printcs` | `SI` = string, `BL` = color | Print a string with the specified color attribute. Uses INT 10h AH=09h. |
| `printnl` | - | Print a newline. Scrolls the screen if the cursor is at the bottom row. |
| `clears` | - | Clear the entire screen (fill with spaces, attribute `0x07 + currentBg`). Reset cursor to top-left. |

## Cursor (`core/cursor.s`)

| Function | Usage | Description |
|----------|-------|-------------|
| `getcrsr` | Returns `DH` = row, `DL` = column | Get the current cursor position via INT 10h AH=03h. |
| `mvcrsr` | `DH` = row, `DL` = column | Move the cursor to the specified position via INT 10h AH=02h. |

## Input (`core/input.s`)

| Function | Usage | Description |
|----------|-------|-------------|
| `getchar` | Returns `AL` = character | Blocking keyboard read. Waits for a keypress via INT 16h AH=00h. |
| `userInput` | `SI` = buffer (32 bytes) | Full line-editing input routine. Handles backspace, displays typed characters, null-terminates on Enter. |

## Utility (`core/utils.s`)

| Function | Usage | Description |
|----------|-------|-------------|
| `memcmp_n` | `SI` = ptr1, `DI` = ptr2, `BX` = length. Returns `AL` = 1 if equal, 0 otherwise. | Compare `BX` bytes at two memory locations. |
| `streq` | `SI` = str1, `DI` = str2. Returns `AL` = 1 if equal, 0 otherwise. | Compare two null-terminated strings. |
| `strlen` | `SI` = string. Returns `AX` = length. | Count characters in a null-terminated string. |
| `atoi` | `SI` = null-terminated string. Returns `AX` = integer. | Convert ASCII decimal string to a signed 16-bit integer. Supports negative numbers. |
| `itoa` | `AX` = integer, `SI` = buffer, `BX` = buffer length. Returns `DI` = bytes written. | Convert a signed 16-bit integer to an ASCII decimal string. Null-terminates the result. |
| `strhex` | `SI` = string (e.g. `"0xF"`). Returns `AX` = value. | Convert a hex string to a 16-bit integer. Skips optional `0x` prefix. |
| `sleep` | `AX` = ticks | Busy-wait for `AX` timer ticks (~18.2 ticks/second). Uses INT 18h AH=00h. |

## FAT16 Filesystem

### Initialization (`core/fat16_bpb.s`, `core/fat16.s`)

| Function | Description |
|----------|-------------|
| `fat16_init` | Initialize the FAT16 filesystem. Reads the BPB from the boot sector, loads the FAT into memory, and locates the root directory. Called once at kernel startup. |
| `fat16_read_bpb` | Parse the BIOS Parameter Block at `0x0800:0x0000` into kernel variables (`bpb_*`). |
| `fat16_read_fat` | Load the entire FAT into `fat_buffer` (16 KB at a fixed offset). |
| `fat16_read_cluster` | Read a single cluster from disk into `cluster_buffer`. |

### Directory Operations (`core/fat16_dir.s`)

| Function | Usage | Description |
|----------|-------|-------------|
| `fat16_list_dir` | - | List all entries in `current_dir_cluster`. Prints filenames, sizes, and types. |
| `fat16_find_entry` | `AX` = directory cluster, `SI` = 8.3 name. Returns `AX` = entry pointer or 0. | Search a directory for a file/directory by 8.3 name. |
| `fat16_name_to_83` | `SI` = input name (e.g. `"file.txt"`), `DI` = output buffer (11 bytes). | Convert a filename to 8.3 format (8-char name + 3-char extension, space-padded, uppercase). |
| `fat16_get_next_cluster` | `AX` = current cluster. Returns `AX` = next cluster. | Follow the FAT chain to get the next cluster for a file. |

### File Operations (`core/fat16_file.s`)

| Function | Usage | Description |
|----------|-------|-------------|
| `fat16_file_read` | `SI` = 8.3 name, `BX` = buffer offset, `CX` = max bytes. Returns `AX` = bytes read (0 = not found). | Read a file from the current directory into a buffer. |
| `fat16_file_create` | `SI` = 8.3 name. Returns `AL` = 1 success, 0 = already exists. | Create a new empty file in the current directory. |
| `fat16_file_delete` | `SI` = 8.3 name. Returns `AL` = 1 success, 0 = not found. | Delete a file and free its clusters. |
| `fat16_mkdir` | `SI` = 8.3 name. Returns `AL` = 1 success, 0 = fail. | Create a new directory. |

### Key Variables

| Variable | Type | Description |
|----------|------|-------------|
| `current_dir_cluster` | `dw` | Current directory's starting cluster. Set to root dir cluster at init. |
| `fat_buffer` | 16 KB | Cached copy of the FAT in memory. |
| `cluster_buffer` | 512 B | Buffer for reading a single disk cluster. |

## System (`core/system.s`)

| Function | Description |
|----------|-------------|
| `shtdwn` | Shutdown via APM (INT 15h). Falls back to QEMU virtual power-off. |
| `rbt` | Reboot via keyboard controller reset command. |
