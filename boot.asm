BITS 16
ORG 0x7C00

entry:
jmp start

%include "print16.inc"
%include "disk.inc"

%define VOLUME_DESCRIPTOR_READ_LOCATION 0x8000

start:

    mov byte [bPhysicalDriveNum], dl	; store the boot disk number.
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00	; set up the stack
    sti

    ;; Print Welcome Message
    mov si, welcome_msg
    call PrintString16BIOS
    call PrintNewline
    

read_volume_descriptors:
     xor eax, eax	; clear out the eax
     mov esi, eax	; clear out the esi
     mov ax, 0x0000
     mov es, ax		; set es to 0x0000
     mov bx, VOLUME_DESCRIPTOR_READ_LOCATION
     
     mov eax, [dwVolumeDescriptorStartingSector]	; starting sector low 32 bit (0-indexed LBA)
     mov esi, 0		; starting sector high 32 bit
     
     mov ecx, 1		; number of sectors to read
     mov edx, 2048	; Sector sizes in bytes (1 sector = 2048 in ISO 9660)
     call ReadFromDiskUsingExtendedBIOSFunction
     
     ; Verify the PVD identifier 'CD001',
     ; which would be at offset 1 of Volume Descriptor structure.
     mov si, VOLUME_DESCRIPTOR_READ_LOCATION + 1
     mov cx, 5
     mov di, iso_id
     repe cmpsb
     jne .invalid_iso_disk

    ; Valid iso disk identifier.
    mov byte al, [VOLUME_DESCRIPTOR_READ_LOCATION]
    mov si, sVolumeDescriptorTypeStatement
    call PrintString16BIOS
    call PrintWordNumber
    call PrintNewline
    cmp al, 0x01	; Check for the Primary Volume Descriptor (PVD)
    jne .read_next_volume_descriptor	; If not PVD, read next descriptor
    
    ; Got PVD
    mov si, sGotPVDStatement
    call PrintString16BIOS
    call PrintNewline
    jmp $

.read_next_volume_descriptor:
    cmp al, 0xFF			; Check for the end of volume descriptor list
    					; which is Volume Descriptor Set Terminator
    					; whose type (first byte) is 0xFF.
    je .volume_descriptor_terminator

    add dword [dwVolumeDescriptorStartingSector], 1	; read next sector i.e next volume descriptor.
    jmp read_volume_descriptors


;; Volume Descriptor Set Terminator
.volume_descriptor_terminator:
   mov si, volume_descriptor_terminator_encountered
   call PrintString16BIOS
   jmp $		

.invalid_iso_disk:
    mov si, invalid_iso_disk
    call PrintString16BIOS
    call PrintNewline
    
jmp $


.error:
	mov ah, 0x0e
	mov al, 'e'
	int 0x10


hang:
    cli
    hlt

welcome_msg db 'Welcome to Stage1 Bootloader from ISO 9660.', 0

invalid_iso_disk: db 'Invalid ISO disk identifier.', 0
volume_descriptor_terminator_encountered: db 'Volume Descriptor Set Terminator Encountered.', 0
sVolumeDescriptorTypeStatement: db 'Volume Descriptor Type = ', 0
sGotPVDStatement: db 'Got the PVD.', 0

iso_id db 'CD001'

;Times 510-($-$$) db 0
;DW 0xAA55		; Don't know why the booting works without the magic number.



bPhysicalDriveNum  db  0  ;; Used in common/disk.inc for reading disk.
dwVolumeDescriptorStartingSector dd 16	;; starting sector where the volume descriptor resides.



Times 2048 - ($-$$) db 0	; Padding to 2KB (2048 bytes)
