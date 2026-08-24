getchar: ; get a character from user. 
  mov ah, 0x00
  int 0x16

  ; al = ASCII code of char

  ret
