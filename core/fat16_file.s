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

    ; If called via syscall, switch ES to user DS for writing to user buffer
    ; If called from kernel code, keep ES as kernel DS (0x0800)
    push es
    mov ax, [cs:syscall_user_ds]
    test ax, ax
    jz .fr_copy
    mov es, ax

.fr_copy:
    cmp cx, 0
    je .fr_copy_done
    mov ax, [bp - 6]
    cmp ax, [bp - 4]
    jae .fr_copy_done
    mov al, [si]
    mov es:[bx], al
    inc si
    inc bx
    inc word [bp - 6]
    dec cx
    jmp .fr_copy

.fr_copy_done:
    pop es              ; restore ES

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
  sub sp, 8
  mov [bp - 2], bx ; data
  mov [bp - 4], cx ; bytes
  mov word [bp - 6], 0 ; written
  mov [bp - 8], si     ; save name pointer (fat16_find_entry clobbers SI)

  mov ax, [current_dir_cluster]
  mov si, [bp - 8]
  call fat16_find_entry
  cmp ax, 0
  jne .file_found

  mov si, [bp - 8]
  call fat16_file_create

  mov ax, [current_dir_cluster]
  mov si, [bp - 8]
  call fat16_find_entry
  cmp ax, 0
  je .fw_done

  .file_found:

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

    ; Switch ES to user DS for reading user data buffer
    push es
    mov ax, [cs:syscall_user_ds]
    mov es, ax

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
    mov al, es:[bx]
    mov [si], al
    inc si
    inc bx
    inc word [bp - 6]
    dec cx
    jmp .fw_copy

.fw_copy_done:
    pop es              ; restore ES to 0x0800

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

    ; No next cluster — allocate and link
    call fat16_allocate_cluster
    cmp ax, 0
    je .fw_update_size
    mov dx, ax                ; dx = new cluster (value to write)
    mov ax, [.fw_cluster]     ; ax = current cluster (entry to set)
    call fat16_set_fat_entry  ; FAT[current] = new_cluster
    mov ax, dx
    mov [.fw_cluster], ax
    jmp .fw_write_loop

.fw_chain_ok:
    mov [.fw_cluster], ax
    jmp .fw_write_loop

.fw_update_size:
    call fat16_write_fat

    ; Re-read directory into cluster_buffer to update the entry
    cmp word [current_dir_cluster], 0
    je .fw_re_read_root
    mov ax, [current_dir_cluster]
    mov di, cluster_buffer
    call fat16_read_cluster
    jmp .fw_update_entry

.fw_re_read_root:
    mov ax, [root_dir_start]
    mov bx, ax
    mov di, cluster_buffer
    call disk_read_sector

.fw_update_entry:
    ; Find the entry again in cluster_buffer
    mov si, cluster_buffer
    mov cx, 16               ; one sector = 16 entries max
    mov dx, [bp - 8]         ; dx = name to match
.fw_scan:
    cmp cx, 0
    je .fw_done
    cmp byte [si], 0
    je .fw_done
    cmp byte [si], 0xE5
    je .fw_scan_next
    cmp byte [si + 11], 0x0F
    je .fw_scan_next
    push cx
    push si
    push dx
    mov di, dx
    mov cx, 11
    repe cmpsb
    pop dx
    pop si
    pop cx
    je .fw_found_entry
.fw_scan_next:
    add si, 32
    dec cx
    jmp .fw_scan

.fw_found_entry:
    ; Update starting cluster
    mov ax, [.fw_cluster]
    mov [si + 26], ax
    ; Update file size
    mov ax, [bp - 6]
    mov [si + 28], ax
    ; Write directory back to disk
    cmp word [current_dir_cluster], 0
    je .fw_write_root_dir
    mov ax, [current_dir_cluster]
    mov di, cluster_buffer
    call fat16_write_cluster
    jmp .fw_done

.fw_write_root_dir:
    mov ax, [root_dir_start]
    mov bx, ax
    mov di, cluster_buffer
    call disk_write_sector

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
