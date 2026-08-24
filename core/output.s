currentBg: db 0x00

prints: ; prints a singular singular string | usage: si = string
  pusha

  cld ; clear direction flag to ensure that SI will increment instead of decrementing.

  .loop:
    lodsb

    cmp al, 0 ; check if loaded character is '\0'.
    je .end

    call getcrsr

    mov ah, 0x09

    mov bl, 0x07
    add bl, [currentBg]

    mov bh, 0 ; page
    mov cx, 1 ; times to print
    int 0x10

    inc dl

    call mvcrsr

    jmp .loop

    .end:
      popa 
      ret

printc: ; print a single character. | usage: al = char
  mov ah, 0x0E
  int 0x10

  ret

printcs: ; prints a colored, singular string. | usage: si = string , bl = color.
  cld ; clear direction flag to ensure that SI will increment instead of decrementing.
  call getcrsr ; get cursor position

  .loop:
    lodsb

    cmp al, 0 ; check if loaded character is '\0'.
    je .end

    mov ah, 0x09
    mov bh, 0 ; page
    mov cx, 1 ; times to print
    int 0x10

    inc dl 
    call mvcrsr

    jmp .loop

    .end:
        ret

printnl: ; print a singular newline.
  call getcrsr 

  cmp dh, 24
  je .scroll

  inc dh 
  xor dl, dl 

  call mvcrsr 
  jmp .end 

  .scroll:
    mov ah, 0x06 ; scroll up
    mov al, 1 ; 1 line

    mov bh, 0x07 ; attribute for blank line (white on currentbg)
    add bh, [currentBg]

    mov ch, 0 ; top row
    mov cl, 0 ; left column
    mov dh, 24 ; bottom row
    mov dl, 79 ; right column
    int 0x10

    mov dh, 24
    xor dl, dl
    call mvcrsr

  .end:
    ret

clears: ; clear screen.
  mov ah, 0x06 ; scroll up
  mov al, 0 ; all screen

  mov bh, 0x07 ; attribute for blank line (white on current bg)
  add bh, [currentBg]

  mov ch, 0 ; top row
  mov cl, 0 ; left column
  mov dh, 24 ; bottom row
  mov dl, 79 ; right column
  int 0x10

  call getcrsr
  xor dh, dh
  xor dl, dl
  call mvcrsr

  ret
