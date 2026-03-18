syscallHandler:
    pusha

    cmp ah, 0x00 ; sys_print_char || printc
    je sys_print_char

    cmp ah, 0x01 ; sys_print_string || prints
    je sys_print_string 

    cmp ah, 0x02 ; sys_print_newline || printnl
    je sys_print_newline

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

sys_done:
    popa
    iret