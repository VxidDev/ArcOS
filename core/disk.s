disk_read_sector: ; Read 1 sector from LBA to buffer. BX=LBA, DI=buffer
    pusha
    mov [kernel_dap_lba], bx
    mov [kernel_dap_buf], di
    mov word [kernel_dap_seg], ds
    mov word [kernel_dap_count], 1
    mov si, kernel_dap
    mov ah, 0x42
    mov dl, [kernel_bootdrive]
    int 0x13
    jc .dr_retry
    popa
    ret
.dr_retry:
    mov ah, 0x00
    mov dl, [kernel_bootdrive]
    int 0x13
    popa
    jmp disk_read_sector

disk_write_sector: ; Write 1 sector from buffer to LBA. BX=LBA, DI=buffer
    pusha
    mov [kernel_dap_lba], bx
    mov [kernel_dap_buf], di
    mov word [kernel_dap_seg], ds
    mov word [kernel_dap_count], 1
    mov si, kernel_dap
    mov ah, 0x43
    mov dl, [kernel_bootdrive]
    mov al, 0x01           ; write with verify
    int 0x13
    jc .dw_retry
    popa
    ret
.dw_retry:
    mov ah, 0x00
    mov dl, [kernel_bootdrive]
    int 0x13
    popa
    jmp disk_write_sector

; LBA DAP for kernel disk ops
align 4
kernel_dap:
    db 0x10            ; DAP size
    db 0               ; reserved
kernel_dap_count:
    dw 1               ; sector count
kernel_dap_buf:
    dw 0               ; offset
kernel_dap_seg:
    dw 0               ; segment
kernel_dap_lba:
    dd 0               ; LBA low 32
    dd 0               ; LBA high 32
