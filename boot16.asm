bits 16
org 0x7c00

disk_test:
  mov [BOOT_DRIVE], dl ; BIOS stores the boot drive il DL

  mov bp, 0x8000
  mov sp, bp

  mov bx, 0x9000 ; load data to 0x0000 to 0x9000
  mov dh, 5 ; load 5 sectors
  mov dl, [BOOT_DRIVE]
  call disk_load

  mov dx, [0x9000]
  call print_hex

  mov dx, [0x9000 + 512]
  call print_hex
  jmp $

print: ; put string address in bx
  mov ah, 0x0e ; BIOS TTY mode
  print_loop:
    mov al, [bx]
    cmp al, 0
    je print_end
    int 0x10 ; putch BIOS interrupt
    inc bx
    jmp print_loop
  print_end: ret

print_hex: ; put value to print in dx
  mov bx, HEX_OUT+5 ; start from end of HEX_OUT

  print_hex_loop:
    cmp bx, HEX_OUT+1 ; we should stop at the x char (2nd char)
    je print_hex_end
    mov cx, dx ; move value to cx
    and cl, 0x0f ; save first value bit to cx
    cmp cl, 0x0a ; check if its a number or digit
    jge hex_char

    add cl, "0" ; we have a digit
    jmp write_char
    
    hex_char:
      add cl, "a" - 0x0a ; we have a number bigger than 0x0a, so subtract 0x0a and add "a"  

    write_char:
      mov [bx], cl
      dec bx
      shr dx, 4 ; remember, an hex digit is 4 bits!
      jmp print_hex_loop

  print_hex_end:
    mov bx, HEX_OUT
    call print
    ret

disk_load:
  push dx

  mov ah, 0x02 ; BIOS read sector function
  mov al, dh ; read DH sectors
  mov ch, 0x00 ; Cylinder 0
  mov dh, 0x00 ; Head 0
  mov cl, 0x02 ; Sector 2 (after the boot sector)

  int 0x13 ; BIOS disk read interrupt

  jc disk_error ; generic read error

  pop dx
  cmp dh, al ; check if all sectors have been read
  jne sect_error

  mov bx, SUCCESS_MSG
  call print

  ret

disk_error:
  mov bx, DISK_ERROR_MSG
  call print
  jmp $

sect_error:
  mov bx, SECT_ERROR_MSG
  call print
  jmp $

HELLO_MSG: db "Hello World!", 10, 13, 0
HEX_OUT: db "0x0000", 10, 13, 0
SUCCESS_MSG: db "Disk readed successfully!", 10, 13, 0
DISK_ERROR_MSG: db "Disk read error!", 10, 13, 0
SECT_ERROR_MSG: db "Sectors read erorr!", 10, 13, 0
BOOT_DRIVE: db 0

times 510 - ($-$$) db 0 ; fill until 510th byte with 0s
dw 0xaa55 ; last two bytes - 512byte sector ending signature

; Familiar words for easily check if they get overwritten
times 256 dw 0xdada
times 256 dw 0xface