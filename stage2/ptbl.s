;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Page Tables
;;;   Sets up a 4 lvl page table with 4 KiB pages, identity-mapped.
;;;   https://wiki.osdev.org/Page_Tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; PML4T entry flags
%define PML4_PRESENT           (1 <<  0) ; Page is present
%define PML4_WRITABLE          (1 <<  1) ; Page is writable
%define PML4_USER              (1 <<  2) ; Page is user-accessible
%define PML4_WRITE_THROUGH     (1 <<  3) ; Write-through caching
%define PML4_CACHE_DISABLE     (1 <<  4) ; Disable caching
%define PML4_ACCESSED          (1 <<  5) ; Page has been accessed
%define PML4_SIZE              (1 <<  7) ; Page size (0 for 4KB, 1 for 2MB/1GB)
%define PML4_EXECUTION_DISABLE (1 << 63) ; Disable execution from this page

; PDPT entry flags
%define PDP_PRESENT            (1 <<  0) ; Page is present
%define PDP_WRITABLE           (1 <<  1) ; Page is writable
%define PDP_USER               (1 <<  2) ; Page is user-accessible
%define PDP_WRITE_THROUGH      (1 <<  3) ; Write-through caching
%define PDP_CACHE_DISABLE      (1 <<  4) ; Disable caching
%define PDP_ACCESSED           (1 <<  5) ; Page has been accessed
%define PDP_SIZE               (1 <<  7) ; 0 when page directory mapped
%define PDP_EXECUTION_DISABLE  (1 << 63) ; Disable execution from this page

; PDT entry flags
%define PD_PRESENT             (1 <<  0) ; Page is present
%define PD_WRITABLE            (1 <<  1) ; Page is writable
%define PD_USER                (1 <<  2) ; Page is user-accessible
%define PD_WRITE_THROUGH       (1 <<  3) ; Write-through caching
%define PD_CACHE_DISABLE       (1 <<  4) ; Disable caching
%define PD_ACCESSED            (1 <<  5) ; Page has been accessed
%define PD_SIZE                (1 <<  7) ; 0 when page table mapped
%define PD_EXECUTION_DISABLE   (1 << 63) ; Disable execution from this page

; PT entry flags
%define PT_PRESENT             (1 <<  0) ; Page is present
%define PT_WRITABLE            (1 <<  1) ; Page is writable
%define PT_USER                (1 <<  2) ; Page is user-accessible
%define PT_WRITE_THROUGH       (1 <<  3) ; Write-through caching
%define PT_CACHE_DISABLE       (1 <<  4) ; Disable caching
%define PT_ACCESSED            (1 <<  5) ; Page has been accessed
%define PT_DIRTY               (1 <<  6) ; Page has been written
%define PT_PAT                 (1 <<  7) ; Page Attribute Table index
%define PT_GLOBAL              (1 <<  8) ; Global page (ignored in PAE)
%define PT_EXECUTION_DISABLE   (1 << 63) ; Disable execution from this page

; Builds a page table entry pointing to the given address with the specified flags
%macro PAGE_ENTRY 2
	; %1 = physical address of next level page table (or page frame)
	; %2 = flags for this entry

	; TODO: This assumes the address is page-aligned and the flags fit in the lower 12 bits
	;       This will be removed in the future when we support dynamic page table allocation
	dq %1 + %2
%endmacro

; Sets up a PML4T entry pointing to the given PDPT address with the specified flags
%macro PML4E 1
	PAGE_ENTRY %1, PML4_PRESENT | PML4_WRITABLE
%endmacro

; Sets up a PDPT entry pointing to the given PDT address with the specified flags
%macro PDPE 1
	PAGE_ENTRY %1, PDP_PRESENT | PDP_WRITABLE
%endmacro

; Sets up a PDT entry pointing to the given PT address with the specified flags
%macro PDE 1
	PAGE_ENTRY %1, PD_PRESENT | PD_WRITABLE
%endmacro

; Sets up a PT entry pointing to the given page frame address with the specified flags
%macro PTE 1
	PAGE_ENTRY %1, PT_PRESENT | PT_WRITABLE
%endmacro

; TODO: remove this static page table setup and support dynamic allocation of page tables in the future

align 0x1000
pml4t:
dq pdpt + 3

align 0x1000
pdpt:
dq pdt + 3

align 0x1000
pdt:
dq 0x00000000 | 0x83

; TODO: remove this static page table setup and support dynamic allocation of page tables in the future

; align 0x1000
; 
; pt:
; 
; ; PT entries = 4 KiB pages, identity-mapped
; %assign i 0
; %rep 512
; 	PTE (i * 0x1000)
; %assign i i + 1
; %endrep
; 
; align 0x1000
; 
; pdt:
; 
; ; PDT entry = PT
; %assign i 0
; %rep 1
; 	PDE (pt + i * 0x1000)
; %assign i i + 1
; %endrep
; 
; align 0x1000
; 
; pdpt:
; 
; ; PDPT entry = PDT
; %assign i 0
; %rep 1
; 	PDPE (pdt + i * 0x1000)
; %assign i i + 1
; %endrep
; 
; align 0x1000
; 
; pml4t:
; 
; ; PML4T entry = PDPT
; %assign i 0
; %rep 1
; 	PML4E (pdpt + i * 0x1000)
; %assign i i + 1
; %endrep