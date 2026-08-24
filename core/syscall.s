syscallHandler:
    pusha

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

    cmp ah, 0x10 ; sys_getchar || getchar
    je sys_getchar

    cmp ah, 0x11 ; sys_get_cursor || getcrsr
    je sys_get_cursor

    cmp ah, 0x12 ; sys_move_cursor || mvcrsr
    je sys_move_cursor

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

  sys_reboot:
    call rbt 
    jmp sys_done ; not needed, but just for sure.

  sys_shutdown:
    call shtdwn 
    jmp sys_done ; not needed, but just for sure.

  sys_done:
    popa
    iret
