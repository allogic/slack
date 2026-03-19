bits 64

global long_mode

extern idt_lm_descriptor
extern setup_idt_lm

section .text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Stage 2 Bootloader - Long Mode
;;;   This is the second stage of the bootloader, loaded by the first stage.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

long_mode:

	; Data segment selector
	mov ax, 0x20

	; Set data segments
	mov es, ax
	mov ss, ax
	mov ds, ax
	mov fs, ax
	mov gs, ax

	; Setup stack pointer
	mov rsp, 0x90000

	; Setup all long mode ISR handlers
	call setup_idt_lm

	; Load the IDT into IDTR register
	lidt [idt_lm_descriptor]

	; Enable interrupts
	sti

	mov rdx, 0x100000 ; Kernel entry point at 1MB
	jmp rdx           ; Jump into kernel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; We should never reach this!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hang_long_mode:

	jmp hang_long_mode