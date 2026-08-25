[org 0x0000]

load_file_prompt:
  mov ah, 0x04 ; sys_print_colored_string
  mov si, loadfileprompt
  mov bl, 0x3F
  int 0x80

  mov ah, 0x14 ; sys_get_line
  mov si, filename
  mov bx, 12
  int 0x80

mov ah, 0x03 ; sys_clear
int 0x80

mov ah, 0x04 ; sys_print_colored_string
mov si, topbar_1
mov bl, 0x0B
int 0x80

mov ah, 0x04
mov si, topbar_2
mov bl, 0x09
int 0x80

mov ah, 0x02 ; sys_print_newline
int 0x80

mov ah, 0x11
int 0x80

mov ah, 0x12 ; sys_move_cursor
mov dl, 0
mov dh, 24
int 0x80

mov ah, 0x04 ; sys_print_colored_string
mov si, bottombar
mov bl, 0x3F
int 0x80

mov ah, 0x12 ; sys_move_cursor
mov dl, 0
mov dh, 1
int 0x80

mov ah, 0x06 ; sys_read_file
mov si, filename
mov bx, buf
mov cx, 4096
int 0x80

; bytes read are at [0x5000], null-terminate after content
mov bx, [0x5000]
add bx, buf
mov byte [bx], 0

mov ah, 0x01 ; sys_print_string
mov si, buf
int 0x80

input:
  mov si, buf
  mov di, buf
  add di, 4096

  .loop:
    mov ah, 0x10 ; sys_getchar
    int 0x80
    
    mov al, [0x5000] ; syscall_ret

    cmp al, 0x0D ; check if enter
    je .enter

    cmp al, 0x08 ; check if backspace
    je .backspace 

    cmp al, 0x13 ; check if CTRL + S
    je .save_file

    cmp al, 0x11 ; check if CTRL + Q
    je .quit

    cmp si, di ; check if user had inputted 4096 bytes
    je .skip

    mov byte [si], al ; store character
    inc si 

    mov ah, 0x00 ; sys_print_char
    int 0x80

    .skip:

    jmp .loop

    .enter:
      cmp si, di ; check buffer limit
      je .loop

      mov byte [si], al
      inc si

      mov ah, 0x02 ; sys_print_newline
      int 0x80

      jmp .loop

    .backspace:
      mov ax, di
      sub ax, 4096

      cmp si, ax
      je .skipremoval     

      dec si              ; move buffer pointer back

      ; move cursor back
      mov ah, 0x11 ; sys_get_cursor
      int 0x80

      mov dh, [0x5000]
      mov dl, [0x5001]

      cmp dl, 0
      jne .bs_no_wrap
      
      cmp dx, 0x0100
      je .skipremoval
      
      dec dh
      mov dl, 79
      jmp .bs_move
    
    .bs_no_wrap:
      dec dl
    
    .bs_move:
      mov ah, 0x12 ; sys_move_cursor
      int 0x80

      ; erase character on screen
      mov al, ' '
      mov ah, 0x00 ; sys_print_char
      int 0x80

      ; move cursor back again (printc advanced it)
      mov ah, 0x11 ; sys_get_cursor
      int 0x80

      mov dh, [0x5000]
      mov dl, [0x5001]

      cmp dl, 0
      jne .bs2_no_wrap
      cmp dh, 0
      je .skipremoval
      dec dh
      mov dl, 79
      jmp .bs2_move

    .bs2_no_wrap:
      dec dl

    .bs2_move:
      mov ah, 0x12 ; sys_move_cursor
      int 0x80
      jmp .loop
    
    .quit:
      mov ah, 0x03 ; sys_clear
      int 0x80 
    
      retf

    .save_file:
      push si               ; save buffer pointer

      mov ah, 0x05 ; sys_write_file
      mov bx, buf ; buffer
      
      mov cx, si
      sub cx, buf ; amount of bytes

      mov si, filename
      int 0x80

      pop si                ; restore buffer pointer

      mov ah, 0x03 ; sys_clear
      int 0x80

      retf

    .skipremoval:
      jmp .loop

topbar_1: db "TXTEDIT ", 0
topbar_2: times 80 - ($ - topbar_1) db ">"
          db 0

bottombar: db "CTRL + S -> Save | CTRL + Q -> Exit"
bottombar_2: times 80 - ($ - bottombar) db ' '
             db 0 

filename: times 12 db 0
loadfileprompt: db "File Name: ", 0

buf: times 4096 db 0
