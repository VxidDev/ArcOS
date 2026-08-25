getchar: ; get a character from user. 
  mov ah, 0x00
  int 0x16

  ; al = ASCII code of char

  ret

getline: ; read a line of text from user | si = buffer, bx = limit | ax = bytes read 
  mov di, si
  add di, bx

  .loop:
    mov ah, 0x10 ; sys_getchar
    int 0x80
    
    mov al, [0x5000] ; syscall_ret

    cmp al, 0x0D ; check if enter
    je .enter

    cmp al, 0x08 ; check if backspace
    je .backspace 

    cmp si, di ; check if user had reached the limit 
    je .skip

    mov byte [si], al ; store character
    inc si

    mov ah, 0x00 ; sys_print_char
    int 0x80

    .skip:

    jmp .loop

    .enter:
      mov byte [si], 0 ; null-terminate
      jmp .ret

    .backspace:
      mov ax, di
      sub ax, bx

      cmp si, ax
      je .loop     

      dec si              ; move buffer pointer back

      ; move cursor back
      mov ah, 0x11 ; sys_get_cursor
      int 0x80

      mov dh, [0x5000]
      mov dl, [0x5001]

      cmp dl, 0
      jne .bs_no_wrap
      
      cmp dx, 0x0100
      je .loop
      
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
      je .loop
      dec dh
      mov dl, 79
      jmp .bs2_move

    .bs2_no_wrap:
      dec dl

    .bs2_move:
      mov ah, 0x12 ; sys_move_cursor
      int 0x80
      jmp .loop
    
    .ret:
      mov ax, si
      sub ax, di
      add ax, bx
      ret
