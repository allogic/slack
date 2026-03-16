bits 16

start:

	cli                       ; Disable interrupts
	call enable_a20           ; Allow addressing above 1MB
	call load_kernel          ; Load kernel from disk
	call setup_protected_mode ; Switch to protected mode

hang1:
	jmp hang1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Enable A20 line
;   The A20 line allows addressing above 1MB.
;   Without enabling A20 the address bus wraps at 1MB,
;   causing memory corruption.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_a20:

	in al, 0x92       ; Read current state of port 0x92
	or al, 0b00000010 ; Bit 1 controls the A20 line on many chipsets
	out 0x92, al      ; Write back to port 0x92 to enable A20

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load kernel into memory
;   Reads sectors from disk into RAM where the kernel will live.
;   Uses BIOS interrupt 13h.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_kernel:

	; ES:BX will be the destination buffer
	; 0x1000 * 16 = 0x10000 physical address
	mov ax, 0x1000
	mov es, ax

	mov bx, 0     ; Destination = 0x1000:0000 = 0x10000

	mov ah, 0x02  ; BIOS disk read function
	mov al, 100   ; Number of sectors to read

	mov ch, 0     ; Cylinder
	mov dh, 0     ; Head
	mov cl, 34    ; Sector

	mov dl, 0x80  ; First hard drive

	int 0x13      ; BIOS disk read

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Global Descriptor Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gdt_start:

dq 0 ; Null descriptor

gdt_code:

; Code segment descriptor
;
; Base = 0
; Limit = 4GB
; Flags:
;   Present
;   Ring 0
;   Executable
;   Readable
;   32-bit
;   Granularity = 4KB
dq 0x00AF9A000000FFFF

gdt_data:

; Data segment descriptor
;
; Base = 0
; Limit = 4GB
; Read/Write
dq 0x00AF92000000FFFF

gdt_end:

gdt_descriptor:

dw gdt_end - gdt_start - 1 ; Size of GDT minus 1 (required by lgdt)
dd gdt_start               ; Linear address of GDT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Switch to protected mode
;   Switch CPU from 16-bit real mode → 32-bit protected mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_protected_mode:

	lgdt [gdt_descriptor] ; Load the GDT into GDTR register

	; Enable PM (Protected Mode)
	mov eax, cr0
	or eax, 1
	mov cr0, eax

	; Far jump:
	;   selector = 0x08 (GDT code segment)
	;   offset = protected_mode
	; This reloads CS and fully enters protected mode
	jmp 0x08:protected_mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 32-bit protected mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bits 32

protected_mode:

	; 0x10 = data segment selector in GDT
	mov ax, 0x10

	; Set data segments
	mov ds, ax
	mov ss, ax

	; Setup stack pointer
	mov esp, 0x90000

	; Prepare paging and enable long mode
	call setup_long_mode

hang2:
	jmp hang2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Setup paging for long mode and switch to long mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_mode:

	; Load address of PML4
	mov eax, pml4 ; PML4 is the top-level page table
	mov cr3, eax  ; CR3 = base of paging structures

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

	; Far jump:
	;   selector = 0x08 (GDT code segment)
	;   offset = long_mode
	; This reloads CS and fully enters long mode
	jmp 0x08:long_mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Page tables (identity map)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 0x1000

pml4:

; PML4 entry = PDPT
; +3 sets:
;   present
;   writable
dq pdpt + 3

align 0x1000

pdpt:

; PDPT entry = PD
; +3 sets:
;   present
;   writable
dq pd + 3

align 0x1000

pd:

; 2MB identity-mapped page
;
; present
; writable
; page size = 2MB
dq 0x00000000 | 0x83

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 64-bit long mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bits 64

long_mode:

	; 0x10 = data segment selector in GDT
	mov ax, 0x10

	; Set data segments
	mov ds, ax
	mov ss, ax

	mov rdx, 0x100000 ; Kernel entry point at 1MB
	jmp rdx           ; Enter kernel

halt:
	hlt
	jmp halt