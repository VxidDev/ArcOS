fat16_file_read: ; Read file. SI=8.3 name, BX=buffer, CX=max bytes. Returns AX=bytes read
    push bp
    mov bp, sp
    sub sp, 6
    mov [bp - 2], bx      ; buffer
    mov [bp - 4], cx      ; max bytes
    mov word [bp - 6], 0   ; bytes_read

    mov ax, [current_dir_cluster]
    call fat16_find_entry
    cmp ax, 0
    je .fr_done

    mov si, ax
    mov ax, [si + 26]
    cmp ax, 0
    je .fr_done
    mov [.fr_cluster], ax

.fr_read_loop:
    mov ax, [bp - 6]
    cmp ax, [bp - 4]
    jae .fr_done

    cmp word [.fr_cluster], 0
    je .fr_done

    mov ax, [.fr_cluster]
    mov di, cluster_buffer
    call fat16_read_cluster

    mov si, cluster_buffer
    mov bx, [bp - 2]
    add bx, [bp - 6]
    mov cx, 512

.fr_copy:
    cmp cx, 0
    je .fr_copy_done
    mov ax, [bp - 6]
    cmp ax, [bp - 4]
    jae .fr_copy_done
    mov al, [si]
    mov [bx], al
    inc si
    inc bx
    inc word [bp - 6]
    dec cx
    jmp .fr_copy

.fr_copy_done:
    mov ax, [.fr_cluster]
    call fat16_next_cluster
    mov [.fr_cluster], ax
    jmp .fr_read_loop

.fr_done:
    mov ax, [bp - 6]
    mov sp, bp
    pop bp
    ret

.fr_cluster: dw 0

fat16_file_write: ; Write file. SI=8.3 name, BX=data, CX=bytes. Returns AX=bytes written
    push bp
    mov bp, sp
    sub sp, 6
    mov [bp - 2], bx      ; data
    mov [bp - 4], cx      ; bytes
    mov word [bp - 6], 0   ; written

    mov ax, [current_dir_cluster]
    call fat16_find_entry
    cmp ax, 0
    je .fw_done

    mov [.fw_entry], ax
    mov si, ax
    mov ax, [si + 26]
    mov [.fw_cluster], ax

    cmp word [bp - 4], 0
    je .fw_update_size

.fw_write_loop:
    mov ax, [.fw_cluster]
    cmp ax, 0
    jne .fw_have_cluster

    call fat16_allocate_cluster
    cmp ax, 0
    je .fw_update_size
    mov [.fw_cluster], ax
    mov bx, [.fw_entry]
    mov [bx + 26], ax

.fw_have_cluster:
    mov ax, [.fw_cluster]
    mov di, cluster_buffer
    pusha
    call fat16_read_cluster
    popa

    mov si, cluster_buffer
    mov bx, [bp - 2]
    add bx, [bp - 6]
    mov cx, 512

.fw_copy:
    cmp cx, 0
    je .fw_copy_done
    mov ax, [bp - 6]
    cmp ax, [bp - 4]
    jae .fw_copy_done
    mov al, [bx]
    mov [si], al
    inc si
    inc bx
    inc word [bp - 6]
    dec cx
    jmp .fw_copy

.fw_copy_done:
    mov ax, [.fw_cluster]
    mov di, cluster_buffer
    call fat16_write_cluster

    mov ax, [bp - 6]
    cmp ax, [bp - 4]
    jae .fw_update_size

    mov ax, [.fw_cluster]
    call fat16_next_cluster
    cmp ax, 0
    jne .fw_chain_ok

    call fat16_allocate_cluster
    cmp ax, 0
    je .fw_update_size
    mov bx, [.fw_cluster]
    mov dx, ax
    call fat16_set_fat_entry
    call fat16_write_fat
    mov ax, dx

.fw_chain_ok:
    mov [.fw_cluster], ax
    jmp .fw_write_loop

.fw_update_size:
    call fat16_write_fat
    mov si, [.fw_entry]
    mov ax, [bp - 6]
    mov [si + 28], ax

.fw_done:
    mov ax, [bp - 6]
    mov sp, bp
    pop bp
    ret

.fw_entry: dw 0
.fw_cluster: dw 0

fat16_file_create: ; Create empty file. SI=8.3 name. Returns AL=1 success, 0 fail
    pusha
    mov [.fc_name], si

    mov ax, [current_dir_cluster]
    call fat16_find_entry
    cmp ax, 0
    jne .fc_exists

    mov ax, [current_dir_cluster]
    cmp ax, 0
    je .fc_root

    mov di, cluster_buffer
    call fat16_read_cluster
    jmp .fc_find_slot

.fc_root:
    mov ax, [root_dir_start]
    mov bx, ax
    mov di, cluster_buffer
    call disk_read_sector

.fc_find_slot:
    mov si, cluster_buffer
    mov cx, 16

.fc_slot_loop:
    cmp cx, 0
    je .fc_no_space
    cmp byte [si], 0
    je .fc_slot_found
    cmp byte [si], 0xE5
    je .fc_slot_found
    add si, 32
    dec cx
    jmp .fc_slot_loop

.fc_slot_found:
    mov di, si
    mov cx, 32
    xor al, al
    rep stosb

    mov di, si
    mov si, [.fc_name]
    push di
    call fat16_name_to_83
    pop di

    mov byte [di + 11], 0x20
    mov word [di + 26], 0
    mov dword [di + 28], 0

    cmp word [current_dir_cluster], 0
    je .fc_write_root

    mov ax, [current_dir_cluster]
    mov di, cluster_buffer
    call fat16_write_cluster
    mov al, 1
    popa
    ret

.fc_write_root:
    mov ax, [root_dir_start]
    mov bx, ax
    mov di, cluster_buffer
    call disk_write_sector
    mov al, 1
    popa
    ret

.fc_exists:
    mov al, 0
    popa
    ret

.fc_no_space:
    mov al, 0
    popa
    ret

.fc_name: dw 0

fat16_file_delete: ; Delete file. SI=8.3 name. Returns AL=1 success, 0 fail
    pusha
    mov ax, [current_dir_cluster]
    call fat16_find_entry
    cmp ax, 0
    je .fd_not_found

    mov si, ax
    mov ax, [si + 26]
    cmp ax, 0
    je .fd_no_clusters
    call fat16_free_chain

.fd_no_clusters:
    mov byte [si], 0xE5

    cmp word [current_dir_cluster], 0
    je .fd_write_root

    mov ax, [current_dir_cluster]
    mov di, cluster_buffer
    call fat16_write_cluster
    mov al, 1
    popa
    ret

.fd_write_root:
    mov ax, [root_dir_start]
    mov bx, ax
    mov di, cluster_buffer
    call disk_write_sector
    mov al, 1
    popa
    ret

.fd_not_found:
    mov al, 0
    popa
    ret

fat16_mkdir: ; Create directory. SI=8.3 name. Returns AL=1 success, 0 fail
    pusha
    mov [.mk_name], si

    call fat16_allocate_cluster
    cmp ax, 0
    je .mk_no_space
    mov [.mk_cluster], ax

    ; Zero out cluster buffer
    mov di, cluster_buffer
    mov cx, 256
    xor ax, ax
    rep stosw

    ; Write . entry
    mov di, cluster_buffer
    mov byte [di], '.'
    mov byte [di + 11], 0x10
    mov ax, [.mk_cluster]
    mov [di + 26], ax

    ; Write .. entry
    mov di, cluster_buffer
    add di, 32
    mov byte [di], '.'
    mov byte [di + 1], '.'
    mov byte [di + 11], 0x10
    mov ax, [current_dir_cluster]
    mov [di + 26], ax

    mov ax, [.mk_cluster]
    mov di, cluster_buffer
    call fat16_write_cluster

    ; Add entry to parent directory
    mov ax, [current_dir_cluster]
    cmp ax, 0
    je .mk_root

    mov di, cluster_buffer
    call fat16_read_cluster
    jmp .mk_find_slot

.mk_root:
    mov ax, [root_dir_start]
    mov bx, ax
    mov di, cluster_buffer
    call disk_read_sector

.mk_find_slot:
    mov si, cluster_buffer
    mov cx, 16

.mk_slot_loop:
    cmp cx, 0
    je .mk_no_space
    cmp byte [si], 0
    je .mk_slot_found
    cmp byte [si], 0xE5
    je .mk_slot_found
    add si, 32
    dec cx
    jmp .mk_slot_loop

.mk_slot_found:
    mov di, si
    mov cx, 32
    xor al, al
    rep stosb

    mov di, si
    mov si, [.mk_name]
    push di
    call fat16_name_to_83
    pop di

    mov byte [di + 11], 0x10
    mov ax, [.mk_cluster]
    mov [di + 26], ax
    mov dword [di + 28], 0

    cmp word [current_dir_cluster], 0
    je .mk_write_root

    mov ax, [current_dir_cluster]
    mov di, cluster_buffer
    call fat16_write_cluster
    mov al, 1
    popa
    ret

.mk_write_root:
    mov ax, [root_dir_start]
    mov bx, ax
    mov di, cluster_buffer
    call disk_write_sector
    mov al, 1
    popa
    ret

.mk_no_space:
    mov al, 0
    popa
    ret

.mk_name: dw 0
.mk_cluster: dw 0
