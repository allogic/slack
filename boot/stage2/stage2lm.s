bits 64

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Stage 2 Bootloader - Long Mode
;;;   This is the second stage of the bootloader, loaded by the first stage.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text

global long_mode

extern idt_lm_descriptor

long_mode:

	; Data segment selector in GDT
	mov ax, 0x20

	; Set data segments
	mov ds, ax
	mov ss, ax

	; Load the IDT into IDTR register
	lidt [idt_lm_descriptor]

	; Setup stack pointer
	mov rsp, 0x90000

	mov rdx, 0x100000 ; Kernel entry point at 1MB
	jmp rdx           ; Jump into kernel

halt:

	hlt
	jmp halt