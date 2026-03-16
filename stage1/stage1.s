bits 16

start:

	; Print message so we know bootloader executed
	mov si, msg
	call print_string

	; Load additional sectors from disk
	call load_stage2

	; Jump to stage2 loader
	jmp 0x0000:0x8000


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Print string using BIOS interrupt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_string:

.next_char:

	lodsb           ; Load byte from [SI] → AL
	or al, al       ; Check if zero terminator
	jz done

	mov ah, 0x0E    ; BIOS teletype output
	int 0x10

	jmp .next_char

done:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load sectors from disk
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_stage2:

	mov bx, 0x8000      ; Load stage2 at

	mov ah, 0x02        ; BIOS disk read function
	mov al, 32          ; Number of sectors to read

	mov ch, 0           ; Cylinder
	mov dh, 0           ; Head
	mov cl, 2           ; Sector

	mov dl, 0x80        ; First hard drive

	int 0x13            ; BIOS disk read

	ret

msg db "Booting slack...",0

; Pad boot sector to 512 bytes
times 510-($-$$) db 0

; Boot signature required by BIOS
dw 0xAA55
