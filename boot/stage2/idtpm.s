bits 32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Protected Mode Interrupt Descriptor Table
;;;   Defines the structure of the protected mode IDT entries.
;;;   https://wiki.osdev.org/Interrupt_Descriptor_Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .rodata

global idt_pm_descriptor

align 8

idt_pm_start:

times 256 dq 0 ; 256 IDT entries, initialized to zero

idt_pm_end:

idt_pm_descriptor:

dw idt_pm_end - idt_pm_start - 1 ; Size of IDT minus 1 (required by lidt)
dd idt_pm_start                  ; Base address of IDT