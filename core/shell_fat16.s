cmd_ls: ; List directory
    call fat16_list_dir
    ret

cmd_cat: ; Print file contents. Usage: cat <filename>
    mov si, inputBuf
    add si, catCmdLen
    cmp byte [si], 0
    je .ca_no_arg
    cmp byte [si], ' '
    jne .ca_no_arg
    inc si

    mov di, cat_83_name
    call fat16_name_to_83

    mov si, cat_83_name
    mov bx, cat_read_buf
    mov cx, 512
    call fat16_file_read
    cmp ax, 0
    je .ca_not_found

    mov byte [cat_read_buf + 511], 0
    mov si, cat_read_buf
    call prints
    call printnl
    ret

.ca_no_arg:
    mov si, cat_usage
    mov bl, 0x07
    call printcs
    call printnl
    ret

.ca_not_found:
    mov si, cat_not_found_msg
    mov bl, 0x04
    call printcs
    call printnl
    ret

cmd_touch: ; Create empty file. Usage: touch <filename>
    mov si, inputBuf
    add si, touchCmdLen
    cmp byte [si], 0
    je .to_no_arg
    cmp byte [si], ' '
    jne .to_no_arg
    inc si

    mov di, touch_83_name
    call fat16_name_to_83

    mov si, touch_83_name
    call fat16_file_create
    cmp al, 0
    je .to_exists
    ret

.to_no_arg:
    mov si, touch_usage
    mov bl, 0x07
    call printcs
    call printnl
    ret

.to_exists:
    mov si, touch_exists_msg
    mov bl, 0x04
    call printcs
    call printnl
    ret

cmd_rm: ; Delete file. Usage: rm <filename>
    mov si, inputBuf
    add si, rmCmdLen
    cmp byte [si], 0
    je .rm_no_arg
    cmp byte [si], ' '
    jne .rm_no_arg
    inc si

    mov di, rm_83_name
    call fat16_name_to_83

    mov si, rm_83_name
    call fat16_file_delete
    cmp al, 0
    je .rm_not_found
    ret

.rm_no_arg:
    mov si, rm_usage
    mov bl, 0x07
    call printcs
    call printnl
    ret

.rm_not_found:
    mov si, rm_not_found_msg
    mov bl, 0x04
    call printcs
    call printnl
    ret

cmd_mkdir_cmd: ; Create directory. Usage: mkdir <name>
    mov si, inputBuf
    add si, mkdirCmdLen
    cmp byte [si], 0
    je .mk_no_arg
    cmp byte [si], ' '
    jne .mk_no_arg
    inc si

    mov di, mkdir_83_name
    call fat16_name_to_83

    mov si, mkdir_83_name
    call fat16_mkdir
    cmp al, 0
    je .mk_fail
    ret

.mk_no_arg:
    mov si, mkdir_usage
    mov bl, 0x07
    call printcs
    call printnl
    ret

.mk_fail:
    mov si, mkdir_fail_msg
    mov bl, 0x04
    call printcs
    call printnl
    ret

cmd_run: ; Run program from disk. Usage: run <filename>
    mov si, inputBuf
    add si, runCmdLen
    cmp byte [si], 0
    je .ru_no_arg
    cmp byte [si], ' '
    jne .ru_no_arg
    inc si

    mov di, run_83_name
    call fat16_name_to_83

    mov si, run_83_name
    mov bx, 0x1000
    mov cx, 8192
    call fat16_file_read
    cmp ax, 0
    je .ru_not_found

    push ds
    push es
    mov ax, 0x0900
    mov ds, ax
    mov es, ax
    call 0x0900:0x0000
    mov ax, 0x0800
    mov ds, ax
    mov es, ax
    pop es
    pop ds
    ret

.ru_no_arg:
    mov si, run_usage
    mov bl, 0x07
    call printcs
    call printnl
    ret

.ru_not_found:
    mov si, run_not_found_msg
    mov bl, 0x04
    call printcs
    call printnl
    ret

cat_83_name: times 11 db 0
cat_read_buf: times 512 db 0
cat_usage: db "Usage: cat <filename>", 0
cat_not_found_msg: db "File not found!", 0

touch_83_name: times 11 db 0
touch_usage: db "Usage: touch <filename>", 0
touch_exists_msg: db "File already exists!", 0

rm_83_name: times 11 db 0
rm_usage: db "Usage: rm <filename>", 0
rm_not_found_msg: db "File not found!", 0

mkdir_83_name: times 11 db 0
mkdir_usage: db "Usage: mkdir <name>", 0
mkdir_fail_msg: db "Failed to create directory!", 0

run_83_name: times 11 db 0
run_usage: db "Usage: run <filename>", 0
run_not_found_msg: db "File not found!", 0
