fat16_read_bpb: ; Read FAT16 BPB from boot sector into bpb variables
    pusha
    mov bx, 0
    mov di, bpb_buffer
    call disk_read_sector

    mov si, bpb_buffer
    add si, 11

    lodsw                 ; [11] bytes_per_sector
    mov al, [si]          ; [13] sectors_per_cluster
    mov [bpb_sectors_per_cluster], al
    inc si
    lodsw                 ; [14] reserved_sectors
    mov [bpb_reserved_sectors], ax
    mov al, [si]          ; [16] num_fats
    mov [bpb_num_fats_copy], al
    inc si
    lodsw                 ; [17] max_root_entries
    mov [bpb_max_root_entries], ax
    lodsw                 ; [19] total_sectors
    mov [bpb_total_sectors], ax
    inc si                ; [21] media_descriptor (skip)
    lodsw                 ; [22] sectors_per_fat
    mov [bpb_sectors_per_fat], ax
    lodsw                 ; [24] sectors_per_track
    mov [bpb_sectors_per_track], ax
    lodsw                 ; [26] num_heads
    mov [bpb_num_heads], ax

    popa
    ret
