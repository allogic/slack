bits 16

section .text

global start

extern get_memory_map

start:

	cli                       ; Disable interrupts
	call enable_a20           ; Allow addressing above 1MB
	call get_memory_map       ; Get memory map from BIOS
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
;;;   Switch CPU from 16-bit real mode → 32-bit protected mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extern gdt_descriptor

setup_protected_mode:

	lgdt [gdt_descriptor] ; Load the GDT into GDTR register

	; Enable PM (Protected Mode)
	mov eax, cr0
	or eax, 1
	mov cr0, eax

	; This reloads CS and fully enters protected mode
	jmp 0x08:protected_mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 32-bit Protected Mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bits 32

protected_mode:

	; Data segment selector in GDT
	mov ax, 0x18

	; Set data segments
	mov ds, ax
	mov ss, ax

	; Setup stack pointer
	mov esp, 0x90000

	; Prepare paging and enable long mode
	call setup_long_mode

hang_protected_mode:
	jmp hang_protected_mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Setup paging for long mode and switch to long mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extern pml4t

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 64-bit Long Mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bits 64

long_mode:

	; Data segment selector in GDT
	mov ax, 0x20

	; Set data segments
	mov ds, ax
	mov ss, ax

	mov rdx, 0x100000 ; Kernel entry point at 1MB
	call rdx          ; Enter kernel

halt:
	hlt
	jmp halt