bits 16

start:

	cli                 ; Disable interrupts

	call enable_a20     ; Allow addressing above 1MB

	call load_kernel    ; Load kernel from disk

	call enter_protected_mode

hang1:
	jmp hang1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Enable A20 line
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_a20:

	in al, 0x92
	or al, 0b00000010
	out 0x92, al

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load kernel into memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_kernel:

	;mov bx, 0x100000        ; Load kernel at
	mov ax, 0x1000
	mov es, ax
	mov bx, 0

	mov ah, 0x02            ; BIOS disk read function
	mov al, 100             ; Number of sectors to read

	mov ch, 0               ; Cylinder
	mov dh, 0               ; Head
	mov cl, 22              ; Sector

	mov dl, 0x80            ; First hard drive

	int 0x13                ; BIOS disk read

	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Global Descriptor Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gdt_start:

dq 0                        ; Null descriptor

gdt_code:
dq 0x00AF9A000000FFFF       ; Code segment

gdt_data:
dq 0x00AF92000000FFFF       ; Data segment

gdt_end:

gdt_descriptor:

dw gdt_end - gdt_start - 1
dd gdt_start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Switch to protected mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_protected_mode:

	lgdt [gdt_descriptor]

	mov eax, cr0
	or eax, 1               ; Enable protected mode
	mov cr0, eax

	jmp 0x08:protected_mode ; Far jump to reload CS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 32-bit protected mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bits 32

protected_mode:

	mov ax, 0x10
	mov ds, ax
	mov ss, ax
	mov esp, 0x90000

	call setup_long_mode

hang2:
	jmp hang2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Setup paging for long mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_long_mode:

	; Load address of PML4
	mov eax, pml4
	mov cr3, eax

	; Enable PAE
	mov eax, cr4
	or eax, (1 << 5)
	mov cr4, eax

	; Enable long mode via MSR
	mov ecx, 0xC0000080
	rdmsr
	or eax, (1 << 8)
	wrmsr

	; Enable paging
	mov eax, cr0
	or eax, (1 << 31)
	mov cr0, eax

	; Jump to 64-bit mode
	jmp 0x08:long_mode

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Page tables (identity map)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 0x1000
pml4:
dq pdpt + 3

align 0x1000
pdpt:
dq pd + 3

align 0x1000
pd:
dq 0x00000000 | 0x83

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 64-bit long mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bits 64

;extern kernel_main

long_mode:

	mov ax, 0x10
	mov ds, ax
	mov ss, ax

	;call kernel_main

halt:
	hlt
	jmp halt