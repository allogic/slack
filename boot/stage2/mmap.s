bits 16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Memory Map
;;;   Defines the structure for E820 memory map entries and a function
;;;   to retrieve the memory map from the BIOS.
;;;   https://wiki.osdev.org/Detecting_Memory_(x86)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; E820 memory map entry structure (24 bytes)
; struc e820_entry
; 	.base_low  resd 1 ; Base address of the memory region (lower 32 bits)
; 	.base_high resd 1 ; Base address of the memory region (upper 32 bits)
; 	.len_low   resd 1 ; Length of the memory region in bytes (lower 32 bits)
; 	.len_high  resd 1 ; Length of the memory region in bytes (upper 32 bits)
; 	.type      resd 1 ; Type of memory region (1 = usable, other values indicate reserved or special regions)
; 	.acpi      resd 1 ; ACPI extended attributes
; endstruc

section .text

global get_memory_map

get_memory_map:
	xor ebx, ebx                 ; Continuation value = 0

	mov ax, 0x1800               ; Buffer for memory map entries
	mov es, ax
	mov ds, ax

	mov dword [0x0000], 0        ; Clear count of entries at 0x18000
	mov di, 0x0008               ; Entries start at 0x18008

.next_entry:
	mov eax, 0xE820              ; E820h - Get Memory Map
	mov edx, 0x534D4150          ; 'SMAP'
	mov ecx, 24                  ; Size of buffer
	int 0x15

	jc .done                     ; Carry = error/end

	cmp eax, 0x534D4150          ; 'SMAP'
	jne .done                    ; Invalid response

	add di, 24                   ; Next slot
	inc dword [0x0000]           ; Increment count of entries

	test ebx, ebx
	jne .next_entry              ; Continue if EBX != 0

.done:
	ret