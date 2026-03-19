bits 64

global idt_lm_descriptor
global setup_idt_lm

section .idt_lm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Long Mode Interrupt Descriptor Table
;;;   Defines the structure of the long mode IDT entries.
;;;   https://wiki.osdev.org/Interrupt_Descriptor_Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Flags builder
%define IDT_LM_FLAGS(pres, dpl, gate) \
	( ((pres) << 7) | ((dpl & 0x03) << 5) | (gate & 0x0F) )

; Present, Ring 0, Interrupt gate
%define IDT_LM_FLAG_INT_GATE \
	IDT_LM_FLAGS(1, 0, 0xE)

idt_lm_start:

times 256 dq 0, 0 ; 256 IDT entries, initialized to zero

idt_lm_end:

idt_lm_descriptor:

dw idt_lm_end - idt_lm_start - 1 ; Size of IDT minus 1 (required by lidt)
dd idt_lm_start                  ; Base address of IDT

section .text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Sets an entry in the long mode IDT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_idt_lm_entry:

	; Arguments
	mov rax, [rsp + 8]  ; rax = vector
	mov rdx, [rsp + 16] ; rdx = handler

	; Compute entry address
	mov rcx, rax
	shl rcx, 4
	add rcx, idt_lm_start

	; Write the IDT entry
	mov word [rcx + 0], dx                   ; Offset low            15:00
	mov word [rcx + 2], 0x10                 ; Code segment selector 31:16
	mov byte [rcx + 4], 0                    ; Interrupt stack table 34:32
	mov byte [rcx + 5], IDT_LM_FLAG_INT_GATE ; Flags                 43:40

	; Offset mid (bits 16–31)                                        63:48
	mov rax, rdx
	shr rax, 16
	mov word [rcx + 6], ax

	; Offset high (bits 32–63)                                       95:64
	shr rax, 16
	mov dword [rcx + 8], eax

	; Reserved                                                      127:96
	mov dword [rcx + 12], 0

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup all long mode ISR handlers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_idt_lm:

	; Register handlers for vectors 0-21
%assign i 0
%rep 22
	push isr%+i%+_lm_stub
	push i
	call set_idt_lm_entry
	add rsp, 16
%assign i i + 1
%endrep

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Generic handler for hardware interrupts (IRQs) coming from the PIC.
;;;   The slave PIC is connected to the master PIC via IRQ2.
;;;   So for IRQs >= 8, we must acknowledge BOTH PICs.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

common_lm_irq_handler:

	cmp rdi, 8               ; Compare IRQ number with 8
	jl master_lm_irq_handler ; If IRQ < 8:

	mov al, 0x20             ; End Of Interrupt (EOI) command
	out 0xA0, al             ; Send EOI to SLAVE PIC (port 0xA0)

master_lm_irq_handler:

	mov al, 0x20             ; End Of Interrupt (EOI) command
	out 0x20, al             ; Send EOI to MASTER PIC (port 0x20)

	iretq

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Divide Error
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr0_lm_stub:

	mov rdi, 0
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Debug Exception
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr1_lm_stub:

	mov rdi, 1
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; NMI Interrupt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr2_lm_stub:

	mov rdi, 2
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Breakpoint
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr3_lm_stub:

	mov rdi, 3
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Overflow
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr4_lm_stub:

	mov rdi, 4
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; BOUND Range Exceeded
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr5_lm_stub:

	mov rdi, 5
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Invalid Opcode (Undefined Opcode)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr6_lm_stub:

	mov rdi, 6
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Device Not Available (No Math Coprocessor)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr7_lm_stub:

	mov rdi, 7
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Double Fault
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr8_lm_stub:

	mov rdi, 8
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Coprocessor Segment Overrun (reserved)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr9_lm_stub:

	mov rdi, 9
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Invalid TSS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr10_lm_stub:

	mov rdi, 10
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Segment Not Present
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr11_lm_stub:

	mov rdi, 11
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Stack-Segment Fault
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr12_lm_stub:

	mov rdi, 12
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; General Protection
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr13_lm_stub:

	mov rdi, 13
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Page Fault
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr14_lm_stub:

	mov rdi, 14
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Intel reserved (Do not use)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr15_lm_stub:

	mov rdi, 15
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; x87 FPU Floating-Point Error (Math Fault)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr16_lm_stub:

	mov rdi, 16
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Alignment Check
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr17_lm_stub:

	mov rdi, 17
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Machine Check
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr18_lm_stub:

	mov rdi, 18
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SIMD Floating-Point Exception
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr19_lm_stub:

	mov rdi, 19
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Virtualization Exception
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr20_lm_stub:

	mov rdi, 20
	jmp common_lm_irq_handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Control Protection Exception
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

isr21_lm_stub:

	mov rdi, 21
	jmp common_lm_irq_handler