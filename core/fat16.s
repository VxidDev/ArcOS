fat16_init: ; Initialize FAT16 filesystem - read BPB, compute layout, read FAT
    call fat16_read_bpb

    mov ax, [bpb_reserved_sectors]
    mov [fat_start], ax

    movzx ax, byte [bpb_num_fats_copy]
    mov bx, [bpb_sectors_per_fat]
    mul bx
    add ax, [fat_start]
    mov [root_dir_start], ax

    mov ax, [bpb_max_root_entries]
    shl ax, 5
    mov bx, 512
    xor dx, dx
    div bx
    add ax, [root_dir_start]
    mov [data_start], ax

    mov word [current_dir_cluster], 0
    mov byte [current_path], '/'
    mov byte [current_path + 1], 0

    call fat16_read_fat
    ret

fat16_read_fat: ; Read entire FAT into fat_buffer
    pusha
    mov si, fat_buffer
    mov ax, [fat_start]
    mov cx, [bpb_sectors_per_fat]
.rf_loop:
    push cx
    push ax
    mov bx, ax
    mov di, si
    call disk_read_sector
    pop ax
    pop cx
    inc ax
    add si, 512
    loop .rf_loop
    popa
    ret

fat16_write_fat: ; Write entire FAT from fat_buffer to disk
    pusha
    mov si, fat_buffer
    mov ax, [fat_start]
    mov cx, [bpb_sectors_per_fat]
.wf_loop:
    push cx
    push ax
    mov bx, ax
    mov di, si
    call disk_write_sector
    pop ax
    pop cx
    inc ax
    add si, 512
    loop .wf_loop
    popa
    ret

fat16_get_fat_entry: ; Get FAT16 entry. AX=cluster, returns AX=value
    shl ax, 1
    mov bx, fat_buffer
    add bx, ax
    mov ax, [bx]
    ret

fat16_set_fat_entry: ; Set FAT16 entry. AX=cluster, DX=value
    shl ax, 1
    mov bx, fat_buffer
    add bx, ax
    mov [bx], dx
    ret

fat16_cluster_to_lba: ; Convert cluster to LBA. AX=cluster, returns AX=LBA
    sub ax, 2
    movzx cx, byte [bpb_sectors_per_cluster]
    mul cx
    add ax, [data_start]
    ret

fat16_read_cluster: ; Read cluster to buffer. AX=cluster, DI=buffer
    pusha
    call fat16_cluster_to_lba
    movzx cx, byte [bpb_sectors_per_cluster]
    mov bx, ax
.rc_loop:
    push cx
    call disk_read_sector
    inc bx
    add di, 512
    pop cx
    loop .rc_loop
    popa
    ret

fat16_write_cluster: ; Write cluster from buffer. AX=cluster, DI=buffer
    pusha
    call fat16_cluster_to_lba
    movzx cx, byte [bpb_sectors_per_cluster]
    mov bx, ax
.wc_loop:
    push cx
    call disk_write_sector
    inc bx
    add di, 512
    pop cx
    loop .wc_loop
    popa
    ret

fat16_allocate_cluster: ; Find free cluster, mark used. Returns AX=cluster (0=none)
    push bx
    push cx
    mov cx, [bpb_total_sectors]
    xor ax, ax
.ac_loop:
    inc ax
    cmp ax, cx
    ja .ac_none
    push ax
    call fat16_get_fat_entry
    cmp ax, 0
    pop ax
    je .ac_found
    jmp .ac_loop
.ac_found:
    mov dx, 0x0FF8
    push ax
    call fat16_set_fat_entry
    call fat16_write_fat
    pop ax
    pop cx
    pop bx
    ret
.ac_none:
    xor ax, ax
    pop cx
    pop bx
    ret

fat16_free_chain: ; Free entire cluster chain. AX=first cluster
    push ax
    push bx
.fc_loop:
    mov bx, ax
    call fat16_get_fat_entry
    cmp ax, 0x0FF8
    jae .fc_end
    mov dx, 0
    push ax
    mov ax, bx
    call fat16_set_fat_entry
    pop ax
    jmp .fc_loop
.fc_end:
    mov dx, 0
    mov ax, bx
    call fat16_set_fat_entry
    call fat16_write_fat
    pop bx
    pop ax
    ret

fat16_next_cluster: ; Get next cluster. AX=current, returns AX=next (0=end)
    call fat16_get_fat_entry
    cmp ax, 0x0FF8
    jb .nc_ok
    xor ax, ax
.nc_ok:
    ret
