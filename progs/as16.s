as16: ; compile assembly file to binary
  mov si, inputBuf
  add si, as16CmdLen

  .skip_spaces:
    cmp byte [si], 0
    je .show_usage
    cmp byte [si], ' '
    jne .found_filename
    inc si
    jmp .skip_spaces

  .show_usage:
    mov ah, 0x01
    mov si, as16_usage
    int 0x80
    mov ah, 0x02
    int 0x80
    ret

  .found_filename:
    mov di, as16_filename
    mov cx, 12
    
    .copy_name:
      cmp byte [si], ' '
      je .copy_done
      cmp byte [si], 0
      je .copy_done
      mov al, [si]
      mov [di], al
      inc si
      inc di
      dec cx
      jnz .copy_name
    
    .copy_done:
    
    mov byte [di], 0

  mov ah, 0x06 ; sys_read_file
  mov si, as16_filename
  mov bx, as16_content
  mov cx, 4096
  int 0x80

  mov ax, [0x5000]
  mov si, as16_content
  add si, ax
  mov byte [si], 0
 
  mov si, as16_content

  .tokenize:
    xor bx, bx
    xor cx, cx

    .split:
      mov al, [si + bx]
      cmp al, '"'

      jne .split_check_delim
      xor byte [as16_in_string], 1
      
      inc bx
      jmp .split
      
      .split_check_delim:
      cmp byte [as16_in_string], 1
      je .split_no_delim

      cmp byte [si + bx], ' '
      je .read

      cmp byte [si + bx], 0xA
      je .read

      .split_no_delim:
      cmp al, 0
      je .read
      
      inc bx
      jmp .split

    .read:
      cmp bx, 0
      je .ret

      mov byte [si + bx], 0

      inc bx
      push bx

      cmp byte [si], '0'
      jl .not_digit
      
      cmp byte [si], '9'
      jg .not_digit

      jmp .integer
      
      .not_digit:

      mov di, as16_mov_repr
      call streq

      cmp al, 1
      je .mov
      
      mov di, as16_int_repr
      call streq

      cmp al, 1
      je .int
      
      mov di, as16_ax_repr
      call streq

      cmp al, 1
      je .ax

      mov di, as16_comma_repr
      call streq

      cmp al, 1
      je .comma
      
      mov di, as16_db_repr
      call streq

      cmp al, 1
      je .comma

      mov di, as16_si_repr
      call streq

      cmp al, 1
      je .si
      
      cmp byte [si], 'A'
      jl .not_char
      
      cmp byte [si], 'Z'
      jle .char

      cmp byte [si], 'a'
      jl .not_char

      cmp byte [si], 'z'
      jg .not_char

      jmp .char

      .not_char:

      cmp byte [si], '"'
      je .string

      jmp .invalid

    .mov:
      jmp .read_end

    .int: 
      jmp .read_end

    .ax:
      jmp .read_end
    
    .comma:
      jmp .read_end

    .integer:
      jmp .read_end

    .char:
      jmp .read_end

    .si:
      jmp .read_end

    .string:
      pop bx

      .string_loop:
        cmp byte [si + bx], '"'
        je .string_end
        
        inc bx

        jmp .string_loop

      .string_end:
        push bx
        jmp .read_end

    .invalid:
      mov ah, 0x04
      mov bl, 0x0C
      int 0x80

      mov ah, 0x02
      int 0x80

      pop bx
      jmp .ret

    .read_end:
      pop bx
      add si, bx

      jmp .tokenize

  .ret:
    ret

as16_filename: times 13 db 0
as16_content: times 4096 db 0

as16_invalid_repr: db "error: invalid instruction: ", 0
as16_usage: db "usage: as16 <filename>", 0

as16_mov_repr: db "mov", 0
as16_int_repr: db "int", 0
as16_ax_repr: db "ax", 0
as16_db_repr: db "db", 0
as16_retf_repr: db "retf", 0
as16_comma_repr: db ",", 0
as16_si_repr: db "si", 0

as16_MAX_TOKENS equ 256

as16_TOK_MOV equ 0
as16_TOK_INT equ 1
as16_TOK_INTERRUPT equ 2
as16_TOK_REG_AX equ 3
as16_TOK_STRING equ 4
as16_TOK_COMMA equ 5

as16_TOK_STRING_SIZE equ 32

section .bss:
  as16_token_types: resb as16_MAX_TOKENS
  as16_token_values: resq as16_MAX_TOKENS
  as16_token_strings: resb as16_TOK_STRING_SIZE * as16_MAX_TOKENS 
  as16_in_string: resb 1
