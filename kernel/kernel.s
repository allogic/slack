bits 64

section .text

global start

extern main

start:

	call main ; Call the main function in the kernel

halt:
	hlt
	jmp halt

section .note.GNU-stack noalloc noexec nowrite progbits