bits 16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Stage 2 Bootloader - Real Mode
;;;   This is the second stage of the bootloader, loaded by the first stage.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text

global start

extern get_memory_map
extern gdt_descriptor
extern protected_mode

start:

	cli                       ; Disable interrupts
	call enable_a20           ; Allow addressing above 1MB
	; call get_memory_map       ; Get memory map from BIOS
	call load_kernel          ; Load kernel from disk
	call setup_protected_mode ; Switch to protected mode

hang_real_mode:

	jmp hang_real_mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Enable A20 line
;;;   The A20 line allows addressing above 1MB.
;;;   Without enabling A20 the address bus wraps at 1MB,
;;;   causing memory corruption.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_a20:

	in al, 0x92       ; Read current state of port 0x92
	or al, 0b00000010 ; Bit 1 controls the A20 line on many chipsets
	out 0x92, al      ; Write back to port 0x92 to enable A20

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Load kernel into memory
;;;   Reads sectors from disk into RAM where the kernel will live.
;;;   Uses BIOS interrupt 13h.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_kernel:

	; ES:BX will be the destination buffer
	; 0x1000 * 16 = 0x10000 physical address
	mov ax, 0x1000
	mov es, ax

	; Destination = 0x1000:0000 = 0x10000
	mov bx, 0

	mov ah, 0x02  ; BIOS disk read function
	mov al, 128   ; Number of sectors to read

	mov ch, 0     ; Cylinder
	mov dh, 0     ; Head
	mov cl, 130   ; Sector

	mov dl, 0x80  ; First hard drive

	int 0x13      ; BIOS disk read

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Switch to protected mode
;;;   Switch CPU from 16-bit real mode -> 32-bit protected mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_protected_mode:

	; Load the GDT into GDTR register
	lgdt [gdt_descriptor]

	; Enable PM (Protected Mode)
	mov eax, cr0
	or eax, 1
	mov cr0, eax

	; This reloads CS and fully enters protected mode
	jmp 0x08:protected_mode