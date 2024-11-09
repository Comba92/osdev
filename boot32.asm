[bits 16]
[org 0x7c00]
KERNEL_OFFSET equ 0x1000

mov [BOOT_DRIVE], dl ; Get boot drive from DL

mov bp, 0x9000
mov sp, bp

mov bx, MSG_REAL_MODE
call print

call load_kernel

call switch_to_pm

hlt

load_kernel:
  mov bx, MSG_LOAD_KERNEL
  call print

  mov bx, KERNEL_OFFSET
  mov dh, 15  ; we want to load the first 15 sectors
  mov dl, [BOOT_DRIVE]
  call disk_load

switch_to_pm:
  cli
  lgdt [gdt_descriptor]

  mov eax, cr0
  or eax, 0x1
  mov cr0, eax

  jmp CODE_SEG:init_pm     ; Far jump to flush pipeline

%include "utils16.asm"

[bits 32]

init_pm:
  mov ax, DATA_SEG
  mov ds, ax
  mov ss, ax
  mov es, ax
  mov fs, ax
  mov gs, ax

  mov ebp, 0x90000
  mov esp, ebp

  call begin_pm

begin_pm:
  mov ebx, MSG_PROT_MODE
  call print_pm

  call KERNEL_OFFSET

  hlt

VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x0f

print_pm:
  pusha
  mov edx, VIDEO_MEMORY
  
  print_pm_loop:
    mov al, [ebx]
    mov ah, WHITE_ON_BLACK

    cmp al, 0
    je print_pm_end

    mov [edx], ax ; putch at video memory

    add ebx, 1
    add edx, 2

    jmp print_pm_loop

  print_pm_end:
    popa
    ret

gdt_start:
  gdt_null: ; starting null descriptor
    dd 0x0
    dd 0x0
  
  gdt_code:
    dw 0xffff       ; Limit (bits 0-15) 
    dw 0x0          ; Base (bits 0-15)
    db 0x0          ; Base (bits 16-23)
    db 10011010b    ; 1st flags, type flags
    db 11001111b    ; 2nd flags, Limit (bits 16-19)
    db 0x0          ; Base (bits 24-31)

  gdt_data:
    dw 0xffff       ; Limit (bits 0-15) 
    dw 0x0          ; Base (bits 0-15)
    db 0x0          ; Base (bits 16-23)
    db 10010010b    ; 1st flags, type flags, only difference
    db 11001111b    ; 2nd flags, Limit (bits 16-19)
    db 0x0          ; Base (bits 24-31)

gdt_end:

gdt_descriptor:
  dw gdt_end - gdt_start - 1 ; size of the GDT
  dd gdt_start               ; start address of the GDT

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

BOOT_DRIVE db 0
MSG_REAL_MODE db "Started in 16-bit Real Mode", 10, 13, 0
MSG_PROT_MODE db "Successfully landed in 32-bit Protected Mode", 0
MSG_LOAD_KERNEL db "Loading kernel into memory", 10, 13, 0

; Bootsector magic padding
times 510 - ($-$$) db 0
dw 0xaa55