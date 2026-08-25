# FAT16 Filesystem

ArcOS includes a minimal FAT16 implementation for reading and writing files on the boot disk.

## How FAT16 Works

FAT16 (File Allocation Table, 16-bit) stores files as chains of clusters on disk. The disk is divided into:

1. **Reserved sectors** - the boot sector (1 sector)
2. **FAT copies** - the File Allocation Table, which maps clusters to the next cluster in a chain (2 copies for redundancy)
3. **Root directory** - a fixed-size area that holds directory entries for files in the root
4. **Data area** - where file and directory content is actually stored

Each file is a linked list of clusters. The FAT is a table where each entry (16 bits) points to the next cluster in the chain. A special value (`0x0FF8` or higher) marks the end of a chain. An entry of `0` means the cluster is free.

## ArcOS Disk Layout

ArcOS creates a 4 MB FAT16 image with these parameters:

| Parameter | Value |
|-----------|-------|
| Bytes per sector | 512 |
| Sectors per cluster | 1 |
| Reserved sectors | 1 |
| Number of FATs | 2 |
| Max root entries | 224 |
| Sectors per FAT | ~32 |
| Root dir size | 14 sectors (224 entries × 32 bytes / 512) |

Layout on disk:

```
Sector 0:        Boot sector (BPB + bootloader code)
Sector 1-32:     FAT copy 1 (File Allocation Table, 32 sectors)
Sector 33-64:    FAT copy 2 (duplicate for redundancy)
Sector 65-78:    Root directory (14 sectors, 224 entries)
Sector 79+:      Data area (clusters start here)
```

Cluster 2 is the first cluster in the data area. Cluster numbers start at 2, so to convert a cluster to a disk sector:

```
LBA = (cluster - 2) * sectors_per_cluster + data_start
```

## BPB (BIOS Parameter Block)

The BPB is at offset 11 in the boot sector. ArcOS reads these fields:

| Offset | Size | Field | Description |
|--------|------|-------|-------------|
| 11 | 2 | bytes_per_sector | Always 512 |
| 13 | 1 | sectors_per_cluster | 1 in ArcOS |
| 14 | 2 | reserved_sectors | 1 (just the boot sector) |
| 16 | 1 | num_fats | 2 |
| 17 | 2 | max_root_entries | 224 |
| 19 | 2 | total_sectors | Total sectors on disk |
| 22 | 2 | sectors_per_fat | Sectors occupied by one FAT copy |
| 24 | 2 | sectors_per_track | Geometry |
| 26 | 2 | num_heads | Geometry |

These are stored in `bpb_*` variables after `fat16_read_bpb` runs.

## Directory Entries

Each directory entry is 32 bytes:

| Offset | Size | Field | Description |
|--------|------|-------|-------------|
| 0 | 8 | name | Filename, space-padded, uppercase |
| 8 | 3 | extension | Extension, space-padded, uppercase |
| 11 | 1 | attributes | File attributes (see below) |
| 26 | 2 | first_cluster | Starting cluster of the file |
| 28 | 4 | file_size | File size in bytes |

**Attribute byte bits:**

| Bit | Meaning |
|-----|---------|
| 0 | Read-only |
| 1 | Hidden |
| 2 | System |
| 3 | Volume label |
| 4 | Subdirectory |
| 5 | Archive |

**Special entry bytes:**

| First byte | Meaning |
|------------|---------|
| `0x00` | Entry is empty (end of directory) |
| `0xE5` | Entry was deleted |

## 8.3 Filename Format

FAT16 uses 8.3 filenames: up to 8 characters for the name, 3 for the extension, stored as 11 bytes with no dot.

Examples:

| Long name | 8.3 format |
|-----------|------------|
| `KERNEL.BIN` | `KERNELBIN` |
| `hello.txt` | `HELLO   TXT` |
| `test` | `TEST       ` |
| `myprog.bin` | `MYPROGBIN` |

ArcOS converts names to 8.3 automatically via `fat16_name_to_83`. Names are uppercased and space-padded.

## Cluster Chains

A file's clusters form a linked list in the FAT. Each FAT entry contains the number of the next cluster, or an end-of-chain marker.

Example for a file that uses clusters 3, 5, and 8:

```
FAT[3] = 5      (next cluster after 3 is 5)
FAT[5] = 8      (next cluster after 5 is 8)
FAT[8] = 0xFF8  (end of chain)
```

**End-of-chain markers:**

| Value | Meaning |
|-------|---------|
| `0x0000` | Free cluster |
| `0x0001` | Reserved |
| `0x0002 - 0xFFEF` | Next cluster number |
| `0xFFF0 - 0xFFF6` | Reserved |
| `0xFFF7` | Bad cluster |
| `0xFFF8 - 0xFFFF` | End of chain |

ArcOS uses `0x0FF8` as the end-of-chain marker.

## Initialization

When the kernel boots, `fat16_init` runs once:

1. Read the boot sector (sector 0) and parse the BPB
2. Compute `fat_start` = reserved_sectors
3. Compute `root_dir_start` = fat_start + (num_fats * sectors_per_fat)
4. Compute `data_start` = root_dir_start + ceil(max_root_entries * 32 / 512)
5. Read the entire FAT into `fat_buffer` (a 16 KB in-memory cache)
6. Set `current_dir_cluster` to 0 (root directory)

## Reading a File

`fat16_file_read` does the following:

1. Find the file's directory entry by searching the current directory for the 8.3 name
2. Get the first cluster number from the entry (offset 26)
3. Loop: read the cluster into `cluster_buffer`, copy bytes to the output buffer via `es:[bx]`, follow the FAT chain to the next cluster
4. Stop when the chain ends or the byte limit is reached

When called from a user program (via syscall), `es` is set to the user's data segment so data is written directly to the program's buffer. When called from kernel code, `es` stays at `0x0800`.

## Writing a File

`fat16_file_write`:

1. Find the directory entry (or create a new one if it doesn't exist)
2. For each chunk of data: allocate a new cluster if needed, read-modify-write the cluster via `es:[bx]`, chain clusters together in the FAT
3. Update the file size in the directory entry
4. Re-read the directory from disk to pick up changes
5. Write the FAT back to disk

When called from a user program (via syscall), `es` is set to the user's data segment so data is read from the program's buffer. The filename must be in 8.3 format before calling.

## Creating a File

`fat16_file_create`:

1. Check if the file already exists
2. Find an empty or deleted slot in the directory
3. Clear the 32-byte entry, write the 8.3 name, set attributes to `0x20` (archive), size to 0, first cluster to 0
4. Write the directory back to disk

## Deleting a File

`fat16_file_delete`:

1. Find the directory entry
2. Free the cluster chain via `fat16_free_chain` (set all FAT entries to 0)
3. Mark the directory entry's first byte as `0xE5` (deleted)
4. Write both the FAT and directory back to disk

## Creating a Directory

`fat16_mkdir`:

1. Allocate a cluster for the new directory
2. Initialize the cluster with two entries:
   - `.` (dot) - points to itself
   - `..` (dot-dot) - points to the parent directory
3. Add a directory entry in the parent with attribute `0x10` (directory)

## Limitations

- **4 MB disk** - the FAT16 cache (16 KB) can only hold ~32 FAT sectors; with 1 sector per cluster, this limits the disk to ~4 MB
- **No subdirectory traversal** - `current_dir_cluster` tracks the current directory, but there's no `cd` command to change it
- **No long filenames** - only 8.3 names are supported
- **Root directory is fixed size** - max 224 entries
- **No file truncation** - `fat16_file_write` can grow files but not shrink them
- **Single-level allocation** - `fat16_allocate_cluster` scans from cluster 1 each time (no free cluster bitmap)
- **No concurrent access** - single-tasking, no file locking

## Key Variables

| Variable | Type | Description |
|----------|------|-------------|
| `fat_start` | `dw` | LBA of the first FAT sector |
| `root_dir_start` | `dw` | LBA of the root directory |
| `data_start` | `dw` | LBA of the first data cluster |
| `current_dir_cluster` | `dw` | Current directory's cluster (0 = root) |
| `fat_buffer` | 16 KB | In-memory copy of the entire FAT |
| `cluster_buffer` | 512 B | Buffer for reading/writing one cluster |
| `bpb_sectors_per_cluster` | `db` | Sectors per cluster |
| `bpb_reserved_sectors` | `dw` | Number of reserved sectors |
| `bpb_num_fats_copy` | `db` | Number of FAT copies (2) |
| `bpb_max_root_entries` | `dw` | Max entries in root directory |
| `bpb_total_sectors` | `dw` | Total sectors on disk |
| `bpb_sectors_per_fat` | `dw` | Sectors per FAT copy |
