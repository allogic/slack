bits 32

global protected_mode

extern pml4t
extern long_mode

section .text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Stage 2 Bootloader - Protected Mode
;;;   This is the second stage of the bootloader, loaded by the first stage.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

protected_mode:

	; Data segment selector
	mov ax, 0x18

	; Set data segments
	mov es, ax
	mov ss, ax
	mov ds, ax
	mov fs, ax
	mov gs, ax

	; Setup stack pointer
	mov esp, 0x90000

	; Prepare paging and enable long mode
	call setup_long_mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; We should never reach this!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hang_protected_mode:

	jmp hang_protected_mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Switch to long mode
;;;   Switch CPU from 32-bit protected mode -> 64-bit long mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_mode:

	; Load address of PML4
	mov eax, pml4t ; PML4 is the top-level page table
	mov cr3, eax   ; CR3 = base of paging structures

	; Enable PAE (Physical Address Extension)
	mov eax, cr4
	or eax, (1 << 5)
	mov cr4, eax

	; Set LME bit in EFER MSR to enable long mode
	mov ecx, 0xC0000080
	rdmsr               ; Read EFER MSR
	or eax, (1 << 8)    ; Set LME (Long Mode Enable)
	wrmsr               ; Write back to EFER MSR

	; Enable paging
	mov eax, cr0
	or eax, (1 << 31)
	mov cr0, eax

	; This reloads CS and fully enters long mode
	jmp 0x10:long_mode