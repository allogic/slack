bits 16

global gdt_descriptor

section .data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Global Descriptor Table
;;;   Defines memory segments for protected and long mode.
;;;   https://wiki.osdev.org/Global_Descriptor_Table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define SEG_DESC(x) ( (x)         << 0x04) ; Descriptor type (0 for system, 1 for code/data)
%define SEG_PRIV(x) (((x) & 0x03) << 0x05) ; Privilege level (0 - 3)
%define SEG_PRES(x) ( (x)         << 0x07) ; Present
%define SEG_SAVL(x) ( (x)         << 0x0C) ; Available for system use
%define SEG_LONG(x) ( (x)         << 0x0D) ; Long mode
%define SEG_SIZE(x) ( (x)         << 0x0E) ; Size (0 for 16-bit, 1 for 32)
%define SEG_GRAN(x) ( (x)         << 0x0F) ; Granularity (0 for 1B - 1MB, 1 for 4KB - 4GB)
%define SEG_TYPE(x) ( (x) & 0x0F         ) ; Accessed / RW / Executable bits

; Access builder
%define SEG_ACCESS(pres, desc, dpl, type) \
	( SEG_PRES(pres) | SEG_DESC(desc) | SEG_PRIV(dpl) | SEG_TYPE(type) )

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
	dw (%1 & 0xFFFF)                            ; Base          31:16
	db ((%1 >> 16) & 0xFF)                      ; Base          39:32
	db %3                                       ; Access        47:40
	db ((%2 >> 16) & 0x0F) | ((%4 & 0x0F) << 4) ; Limit + Flags 55:48
	db ((%1 >> 24) & 0xFF)                      ; Base          63:56
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
%define GDT_PM_CODE_PL0 \
	SEG_ACCESS(1, 1, 0, SEG_CODE_EXRD), SEG_FLAGS(1, 1, 0)

; Code segment descriptor for ring 0 long mode
%define GDT_LM_CODE_PL0 \
	SEG_ACCESS(1, 1, 0, SEG_CODE_EXRD), SEG_FLAGS(1, 1, 1)

; Data segment descriptor for ring 0 protected mode
%define GDT_PM_DATA_PL0 \
	SEG_ACCESS(1, 1, 0, SEG_DATA_RDWR), SEG_FLAGS(1, 1, 0)

; Data segment descriptor for ring 0 long mode
%define GDT_LM_DATA_PL0 \
	SEG_ACCESS(1, 1, 0, SEG_DATA_RDWR), SEG_FLAGS(1, 1, 1)

gdt_start:

dq 0 ; Null descriptor

GDT_ENTRY 0, 0xFFFFF, GDT_PM_CODE_PL0 ; 0x08 = offset of this descriptor in GDT
GDT_ENTRY 0, 0xFFFFF, GDT_LM_CODE_PL0 ; 0x10 = offset of this descriptor in GDT
GDT_ENTRY 0, 0xFFFFF, GDT_PM_DATA_PL0 ; 0x18 = offset of this descriptor in GDT
GDT_ENTRY 0, 0xFFFFF, GDT_LM_DATA_PL0 ; 0x20 = offset of this descriptor in GDT

gdt_end:

gdt_descriptor:

dw gdt_end - gdt_start - 1 ; Size of GDT minus 1 (required by lgdt)
dd gdt_start               ; Base address of GDT