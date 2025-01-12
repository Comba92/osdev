[bits 32]
[extern main]

; only porpuose of this is to get it linked at the top of the final executable
; so we start the program by jumping to the main function
call main
hlt