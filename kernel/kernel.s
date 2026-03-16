global kernel_entry

extern kernel_main

section .text

kernel_entry:

halt:
	hlt
	jmp halt

section .note.GNU-stack noalloc noexec nowrite progbits