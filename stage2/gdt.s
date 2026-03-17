;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Global Descriptor Table
;;;   Defines memory segments for protected and long mode.
;;;   https://wiki.osdev.org/GDT_Tutorial
;;;   https://wiki.osdev.org/Global_Descriptor_Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Descriptor type (0 for system, 1 for code/data)
%define SEG_DESCTYPE(x) ((x) << 4)

; Present
%define SEG_PRES(x) ((x) << 7)

; Privilege level
%define SEG_PRIV(x) (((x) & 3) << 5)

; Accessed / RW / Executable bits
%define SEG_TYPE(x) ((x) & 0x0F)

; Flags
%define SEG_SAVL(x) ((x) << 12)
%define SEG_LONG(x) ((x) << 13)
%define SEG_SIZE(x) ((x) << 14)
%define SEG_GRAN(x) ((x) << 15)

; Access builder
%define SEG_ACCESS(type, dpl) \
	( SEG_PRES(1) | SEG_DESCTYPE(1) | SEG_PRIV(dpl) | SEG_TYPE(type) )

; Flags builder
%define SEG_FLAGS(gran, size, long) \
	( ((gran) << 3) | ((size) << 2) | ((long) << 1) )

; GDT builder
%macro GDT_ENTRY 4
	; %1 = Base
	; %2 = Limit
	; %3 = Access
	; %4 = Flags

	dw (%2 & 0xFFFF)                            ; Limit         15:00
	dw (%1 & 0xFFFF)                            ; Base          16:31
	db ((%1 >> 16) & 0xFF)                      ; Base          32:39
	db %3                                       ; Access        40:47
	db ((%2 >> 16) & 0x0F) | ((%4 & 0x0F) << 4) ; Limit + Flags 48:55
	db ((%1 >> 24) & 0xFF)                      ; Base          56:63
%endmacro

; Common segment types
%define SEG_DATA_RD        0x00 ; Read-Only
%define SEG_DATA_RDA       0x01 ; Read-Only, accessed
%define SEG_DATA_RDWR      0x02 ; Read/Write
%define SEG_DATA_RDWRA     0x03 ; Read/Write, accessed
%define SEG_DATA_RDEXPD    0x04 ; Read-Only, expand-down
%define SEG_DATA_RDEXPDA   0x05 ; Read-Only, expand-down, accessed
%define SEG_DATA_RDWREXPD  0x06 ; Read/Write, expand-down
%define SEG_DATA_RDWREXPDA 0x07 ; Read/Write, expand-down, accessed
%define SEG_CODE_EX        0x08 ; Execute-Only
%define SEG_CODE_EXA       0x09 ; Execute-Only, accessed
%define SEG_CODE_EXRD      0x0A ; Execute/Read
%define SEG_CODE_EXRDA     0x0B ; Execute/Read, accessed
%define SEG_CODE_EXC       0x0C ; Execute-Only, conforming
%define SEG_CODE_EXCA      0x0D ; Execute-Only, conforming, accessed
%define SEG_CODE_EXRDC     0x0E ; Execute/Read, conforming
%define SEG_CODE_EXRDCA    0x0F ; Execute/Read, conforming, accessed

; Code segment descriptor for ring 0 protected mode
%define GDT32_CODE_PL0 \
	SEG_ACCESS(SEG_CODE_EXRD, 0), SEG_FLAGS(1,1,0)

; Code segment descriptor for ring 0 long mode
%define GDT64_CODE_PL0 \
	SEG_ACCESS(SEG_CODE_EXRD, 0), SEG_FLAGS(1,1,1)

; Data segment descriptor for ring 0 protected mode
%define GDT32_DATA_PL0 \
	SEG_ACCESS(SEG_DATA_RDWR, 0), SEG_FLAGS(1,1,0)

; Data segment descriptor for ring 0 long mode
%define GDT64_DATA_PL0 \
	SEG_ACCESS(SEG_DATA_RDWR, 0), SEG_FLAGS(1,1,1)

gdt_start:

dq 0 ; Null descriptor

gdt32_code: ; 0x08 = offset of this descriptor in GDT
GDT_ENTRY 0, 0xFFFFF, GDT32_CODE_PL0

gdt64_code: ; 0x10 = offset of this descriptor in GDT
GDT_ENTRY 0, 0xFFFFF, GDT64_CODE_PL0

gdt32_data: ; 0x18 = offset of this descriptor in GDT
GDT_ENTRY 0, 0xFFFFF, GDT32_DATA_PL0

gdt64_data: ; 0x20 = offset of this descriptor in GDT
GDT_ENTRY 0, 0xFFFFF, GDT64_DATA_PL0

gdt_end:

gdt_descriptor:

dw gdt_end - gdt_start - 1 ; Size of GDT minus 1 (required by lgdt)
dd gdt_start               ; Linear address of GDT