bits 64

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Long Mode Interrupt Descriptor Table
;;;   Defines the structure of the long mode IDT entries.
;;;   https://wiki.osdev.org/Interrupt_Descriptor_Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .rodata

global idt_lm_descriptor

align 16

idt_lm_start:

times 256 dq 0, 0 ; 256 IDT entries, initialized to zero

idt_lm_end:

idt_lm_descriptor:

dw idt_lm_end - idt_lm_start - 1 ; Size of IDT minus 1 (required by lidt)
dd idt_lm_start                  ; Base address of IDT