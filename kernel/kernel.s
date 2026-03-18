bits 64

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Kernel Entry Point
;;;   This is the entry point for the kernel after the bootloader has loaded it into memory.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text

global start
global print_string

extern main

start:

	call main ; Call the main function in the kernel

halt:
	hlt
	jmp halt


; void print_string(char const* str)
; rdi = pointer to string
print_string:

    push rsi
    push rdi

    mov rsi, rdi              ; Source string
    mov rdi, VIDEO_MEMORY     ; Destination (VGA)

.next_char:

    lodsb                     ; AL = *RSI++
    test al, al
    jz .done

    mov ah, WHITE_ON_BLACK
    stosw                     ; write AX to [RDI], RDI += 2

    jmp .next_char

.done:

    pop rdi
    pop rsi
    ret

section .bss

VIDEO_MEMORY equ 0xB8000 ; VGA text mode buffer
WHITE_ON_BLACK equ 0x07  ; White text on black background

section .note.GNU-stack noalloc noexec nowrite progbits