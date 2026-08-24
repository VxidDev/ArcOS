[org 0x0000]

mov ah, 0x03 ; sys_clear
int 0x80

mov ah, 0x01 ; sys_print_string
mov si, topBar
int 0x80

mov ah, 0x02 ; sys_print_newline
int 0x80

input:
  mov ah, 0x10 ; sys_getchar
  int 0x80
  
  mov al, [0x5000] ; syscall_ret

  mov ah, 0x00 ; sys_print_char
  int 0x80

  jmp input

topBar: times 80 db ">"
cursorY: db 1
cursorX: db 0
