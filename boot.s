[org 0x7C3E]
[bits 16]

start:
  cli
  mov [bootdrive], dl
  xor ax, ax
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 0x7C00
  sti

  mov si, msg_boot
  mov bl, 0x0F
  call printcs

  ; Calculate root dir start: reserved + (num_fats * sec_per_fat)
  movzx ax, byte [0x7C10] ; num_fats
  mov cx, [0x7C16] ; sec_per_fat
  mul cx
  add ax, [0x7C0E] ; + reserved_sectors
  mov [root_start], ax

  ; Data area start
  mov ax, [0x7C11] ; root_entries
  shl ax, 5
  shr ax, 9 ; root dir sectors
  add ax, [root_start]
  mov [data_start], ax

  ; Search root dir sectors for KERNEL.BIN
  mov ax, [root_start]
  mov [cur_root_sec], ax
  mov word [secs_left], 14 ; root dir sectors (224*32/512)

  .search_sector:
    cmp word [secs_left], 0
    je .not_found
    mov ax, [cur_root_sec]
    mov [dap_lba], ax
    mov word [dap_buf], 0x7E00
    mov word [dap_seg], 0
    call disk_read_lba

    mov si, 0x7E00
    mov cx, 16 ; entries per sector (512/32)

  .search_entry:
    cmp cx, 0
    je .next_sector
    cmp byte [si], 0
    je .not_found
    cmp byte [si], 0xE5
    je .entry_next
    cmp byte [si + 11], 0x0F
    je .entry_next
    push cx
    push si
    mov di, kernel_name
    mov cx, 11
    repe cmpsb
    pop si
    pop cx
    je .found

  .entry_next:
    add si, 32
    dec cx
    jmp .search_entry

  .next_sector:
    inc word [cur_root_sec]
    dec word [secs_left]
    jmp .search_sector

  .found:
    mov ax, [si + 26]
    mov [kernel_cluster], ax
    mov word [load_seg], 0x0800

  .load_loop:
    mov ax, [kernel_cluster]
    cmp ax, 0x0002
    jb .load_done
    cmp ax, 0xFFF8
    jae .load_done

    mov bx, ax
    sub bx, 2
    movzx ax, byte [0x7C0D]  ; sec_per_clus
    mul bx
    add ax, [data_start]
    mov [dap_lba], ax
    mov word [dap_buf], 0
    mov ax, [load_seg]
    mov [dap_seg], ax
    call disk_read_lba

    add word [load_seg], 0x20 ; 512 bytes = 0x20 paragraphs

    ; Read FAT entry for current cluster
    mov ax, [kernel_cluster]
    mov bx, ax
    shl bx, 1              ; byte offset = cluster * 2
    mov cx, bx
    shr cx, 9              ; FAT sector index
    mov dx, [0x7C0E]
    add dx, cx
    mov [dap_lba], dx
    mov word [dap_buf], 0x7E00
    mov word [dap_seg], 0
    push bx
    call disk_read_lba
    pop bx

    and bx, 0x1FF          ; offset within FAT sector
    mov ax, [0x7E00 + bx]
    mov [kernel_cluster], ax
    jmp .load_loop

  .load_done:
    mov si, msg_loaded
    mov bl, 0x07
    call printcs
    mov dl, [bootdrive]
    jmp 0x0800:0x0000

  .not_found:
    mov si, msg_nokern
    mov bl, 0x04
    call printcs
    jmp $

printcs: ; print null-terminated string. | usage: si = string, bl = color
  xor bh, bh
  .loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x09
    mov cx, 1
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
    jmp .loop
  .done:
    ret

; LBA disk read using INT 13h extensions (AH=42h)
; Uses dap_lba, dap_count, dap_buf, dap_seg variables
disk_read_lba:
  pusha
  mov si, dap
  mov ah, 0x42
  mov dl, [bootdrive]
  int 0x13
  jc .retry
  popa
  ret

  .retry:
    mov ah, 0x00
    mov dl, [bootdrive]
    int 0x13
    popa
    jmp disk_read_lba

bootdrive:      db 0
kernel_name:    db "KERNEL  BIN"
root_start:     dw 0
data_start:     dw 0
kernel_cluster: dw 0
load_seg:       dw 0
cur_root_sec:   dw 0
secs_left:      dw 0

; Disk Address Packet for LBA reads
dap:
  db 0x10 ; DAP size
  db 0 ; reserved

dap_count:
  dw 1 ; sector count

dap_buf:
  dw 0 ; offset

dap_seg:
  dw 0 ; segment

dap_lba:
  dd 0 ; LBA low 32
  dd 0 ; LBA high 32

msg_boot: db "Loading...", 13, 10, 0
msg_loaded: db "Done.", 13, 10, 0
msg_nokern: db "No kernel!", 0

times 448 - ($ - $$) db 0
