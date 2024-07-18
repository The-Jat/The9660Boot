BITS 16
ORG 0x7C00

entry:
jmp start

%include "print16.inc"
%include "disk.inc"
%include "iso9660.inc"



start:

    mov byte [bPhysicalDriveNum], dl	; store the boot disk number (provided by the BIOS in dl)
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00	; set up the stack && stack grows downward (high to low memory)
    sti
    ;; Print Welcome Message
    mov si, welcome_msg
    call PrintString16BIOS
    call PrintNewline

;; Calculate & print the size of the code without padding.
;; It will be in bytes.
	mov si, sUnpaddedSizeStatement
	call PrintString16BIOS
	mov eax, end - entry	; calculate the un-padded size by labels.
	call PrintWordNumber
	call PrintNewline

;; ISO 9660, Read Volume Descriptors.
	call Read_volume_descriptors
jmp $  


hang:
    cli
    hlt

;section .data
welcome_msg db 'Welcome to Stage1 Bootloader from ISO 9660.', 0




;Times 510-($-$$) db 0
;DW 0xAA55		; Don't know why the booting works without the magic number.



bPhysicalDriveNum  db  0  ;; Used in common/disk.inc for reading disk.


;; Mark of unpadded end.
end:

Times 2048 - ($-$$) db 0	; Padding to 1KB (1024 bytes)
