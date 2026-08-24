fat16_list_dir: ; List files in current directory
    pusha
    mov ax, [current_dir_cluster]
    cmp ax, 0
    je .ld_root

    mov di, cluster_buffer
    call fat16_read_cluster
    mov word [.ld_offset], cluster_buffer
    mov ax, 512
    mov bx, 32
    xor dx, dx
    div bx
    mov [.ld_count], ax
    jmp .ld_parse

.ld_root:
    mov ax, [root_dir_start]
    mov bx, ax
    mov di, cluster_buffer
    call disk_read_sector
    mov word [.ld_offset], cluster_buffer
    mov ax, [bpb_max_root_entries]
    mov [.ld_count], ax

.ld_parse:
    cmp word [.ld_count], 0
    je .ld_done

    mov si, [.ld_offset]
    cmp byte [si], 0
    je .ld_done
    cmp byte [si], 0xE5
    je .ld_skip
    cmp byte [si + 11], 0x0F
    je .ld_skip

    pusha
    mov di, temp_name
    mov cx, 8
.ld_cname:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop .ld_cname

    mov byte [di], '.'
    inc di

    mov cx, 3
.ld_cext:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop .ld_cext

    mov byte [di], 0

    mov si, temp_name
    mov bl, 0x07
    call printcs

    mov si, [.ld_offset]
    test byte [si + 11], 0x10
    jz .ld_not_dir

    mov si, dir_marker
    mov bl, 0x0B
    call printcs
    jmp .ld_newline

.ld_not_dir:
    mov si, space_str
    mov bl, 0x07
    call prints

    mov si, [.ld_offset]
    mov ax, [si + 28]
    mov si, itoa_buf
    mov bx, 8
    call itoa

    mov si, itoa_buf
    call prints

.ld_newline:
    call printnl
    popa

.ld_skip:
    add word [.ld_offset], 32
    dec word [.ld_count]
    jmp .ld_parse

.ld_done:
    popa
    ret

.ld_offset: dw 0
.ld_count: dw 0

fat16_find_entry: ; Find 8.3 entry. SI=name(11), AX=dir cluster. Returns AX=entry offset (0=not found)
    push bx
    push cx
    push dx
    mov [.fe_target], si
    mov [.fe_dcluster], ax

    cmp ax, 0
    je .fe_root

    mov ax, [.fe_dcluster]
    mov di, cluster_buffer
    call fat16_read_cluster
    jmp .fe_scan

.fe_root:
    mov ax, [root_dir_start]
    mov bx, ax
    mov di, cluster_buffer
    call disk_read_sector

.fe_scan:
    mov si, cluster_buffer
    mov cx, [bpb_max_root_entries]

.fe_loop:
    cmp cx, 0
    je .fe_not_found

    cmp byte [si], 0
    je .fe_not_found
    cmp byte [si], 0xE5
    je .fe_next
    cmp byte [si + 11], 0x0F
    je .fe_next

    push cx
    push si
    mov di, [.fe_target]
    mov cx, 11
    repe cmpsb
    pop si
    pop cx
    je .fe_found

.fe_next:
    add si, 32
    dec cx
    jmp .fe_loop

.fe_found:
    mov ax, si
    pop dx
    pop cx
    pop bx
    ret

.fe_not_found:
    xor ax, ax
    pop dx
    pop cx
    pop bx
    ret

.fe_target: dw 0
.fe_dcluster: dw 0

fat16_name_to_83: ; Convert name.ext to 8.3 format. SI=input, DI=output (11 bytes)
    push cx
    push dx
    mov cx, 8
    xor dx, dx

.nl_loop:
    cmp byte [si], '.'
    je .nl_dot
    cmp byte [si], 0
    je .nl_pad
    cmp dx, cx
    jae .nl_ext
    mov al, [si]
    cmp al, 'a'
    jb .nl_upper
    cmp al, 'z'
    ja .nl_upper
    sub al, 32
.nl_upper:
    mov [di], al
    inc di
    inc si
    inc dx
    jmp .nl_loop

.nl_pad:
    mov al, ' '
    mov [di], al
    inc di
    inc dx
    cmp dx, 8
    jb .nl_pad
    jmp .nl_ext

.nl_dot:
    inc si
.nl_pd:
    cmp dx, 8
    jae .nl_ext
    mov byte [di], ' '
    inc di
    inc dx
    jmp .nl_pd

.nl_ext:
    mov cx, 3
    xor dx, dx

.el_loop:
    cmp byte [si], 0
    je .el_pad
    cmp dx, cx
    jae .el_done
    mov al, [si]
    cmp al, 'a'
    jb .el_upper
    cmp al, 'z'
    ja .el_upper
    sub al, 32
.el_upper:
    mov [di], al
    inc di
    inc si
    inc dx
    jmp .el_loop

.el_pad:
    mov al, ' '
    mov [di], al
    inc di
    inc dx
    cmp dx, 3
    jb .el_pad

.el_done:
    pop dx
    pop cx
    ret
