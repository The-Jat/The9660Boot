BITS 16
ORG 0x7C00

start:
    ; Print a message to indicate bootloader is running
    mov si, msg
print:
    lodsb
    test al, al
    jz hang
    mov ah, 0x0E
    int 0x10
    jmp print

hang:
    cli
    hlt

msg db 'Stage1 Bootloader from ISO 9660.', 0


;Times 510-($-$$) db 0
;DW 0xAA55		; Don't know why the booting works without the magic number.

Times 2048 - ($-$$) db 0	; Padding to 2KB (2048 bytes)
