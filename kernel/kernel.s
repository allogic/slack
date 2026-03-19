bits 64

global start
global print_string

extern main

section .text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Kernel Entry Point
;;;   This is the entry point for the kernel after the bootloader
;;;   has loaded it into memory.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start:

	call main ; Call the main function in the kernel

	hlt       ; Properly reboot the machine at this point

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; We should never reach this!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hang_kernel:

	jmp hang_kernel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Simple print string function (Debug purpose only)
;;;   rdi = pointer to string
;;;   void print_string(char const* str)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_string:

	push rsi
	push rdi

	mov rsi, rdi                ; Source string
	mov rdi, 0xB8000       ; Destination (VGA)

print_string_next_char:

	lodsb                       ; AL = *RSI++
	test al, al
	jz print_string_done

	mov ah, 0x07
	stosw                       ; write AX to [RDI], RDI += 2

	jmp print_string_next_char

print_string_done:

	pop rdi
	pop rsi

	ret

section .bss

VIDEO_MEMORY equ 0xB8000 ; VGA text mode buffer
WHITE_ON_BLACK equ 0x07  ; White text on black background

section .note.GNU-stack noalloc noexec nowrite progbits