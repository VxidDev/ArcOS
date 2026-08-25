syscallHandler:
    pusha
    push ds
    push es

    ; 0x00 -> 0x10 - output based syscalls
    ; 0x10 -> 0x20 - input based syscalls
    ; 0xA0 -> 0xB0 - system based syscalls 

    cmp ah, 0x00 ; sys_print_char || printc
    je sys_print_char

    cmp ah, 0x01 ; sys_print_string || prints
    je sys_print_string 

    cmp ah, 0x02 ; sys_print_newline || printnl
    je sys_print_newline

    cmp ah, 0x03 ; sys_clear_screen || clears
    je sys_clear_screen
    
    cmp ah, 0x04 ; sys_print_colored_string || printcs
    je sys_print_colored_string

    cmp ah, 0x05 ; sys_write_file || fat16_write_file
    je sys_write_file

    cmp ah, 0x06 ; sys_read_file || fat16_read_file
    je sys_read_file

    cmp ah, 0x10 ; sys_getchar || getchar
    je sys_getchar

    cmp ah, 0x11 ; sys_get_cursor || getcrsr
    je sys_get_cursor

    cmp ah, 0x12 ; sys_move_cursor || mvcrsr
    je sys_move_cursor

    cmp ah, 0x14 ; sys_get_line || getline
    je sys_get_line

    cmp ah, 0xA0 ; sys_shutdown || shtdwn
    je sys_shutdown

    cmp ah, 0xA1 ; sys_reboot || rbt 
    je sys_reboot

    jmp sys_done

  sys_print_char:
    call printc
    jmp sys_done

  sys_print_string:
    call prints 
    jmp sys_done

  sys_print_newline:
    call printnl
    jmp sys_done

  sys_clear_screen:
    call clears
    jmp sys_done

  sys_print_colored_string:
    call printcs
    jmp sys_done
  
  sys_write_file:
    call sys_prepare_filename
    call fat16_file_write
    jmp sys_finish_disk_syscall

  sys_read_file:
    call sys_prepare_filename
    call fat16_file_read
    jmp sys_finish_disk_syscall
    
  sys_prepare_filename:
    mov [cs:syscall_user_ds], ds

    push cx
    push si
    push di
    mov di, temp_name
    mov cx, 13

    .copy_name:
      mov al, [si]
      mov [cs:di], al
      inc si
      inc di
      test al, al
      jz .copy_done
      dec cx
      jnz .copy_name

    .copy_done:
      pop di
      pop si
      pop cx

    ; Switch to kernel DS/ES
    mov ax, 0x0800
    mov ds, ax
    mov es, ax

    ; Convert to 8.3 format in-place
    mov si, temp_name
    mov di, temp_name
    call fat16_name_to_83

    mov si, temp_name
    ret

  sys_finish_disk_syscall:
    mov bx, ax ; Save return value from FAT function
    mov ax, [cs:syscall_user_ds]
    mov ds, ax
    mov [0x5000], bx ; Store return value for user space
    mov ax, 0x0800
    mov ds, ax ; Reset DS back to kernel for next parts if needed
    mov word [cs:syscall_user_ds], 0 ; Reset so kernel callers don't get wrong ES
    jmp sys_done

  sys_getchar:
    call getchar
    mov [0x5000], al
    jmp sys_done
  
  sys_get_cursor:
    call getcrsr
    mov [0x5000], dh
    mov [0x5001], dl 
    jmp sys_done
  
  sys_move_cursor:
    call mvcrsr
    jmp sys_done
  
  sys_get_line:
    call getline
    mov [0x5000], ax
    jmp sys_done

  sys_reboot:
    call rbt 
    jmp sys_done

  sys_shutdown:
    call shtdwn 
    jmp sys_done

  sys_done:
    pop es
    pop ds
    popa
    iret
