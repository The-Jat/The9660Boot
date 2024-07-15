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
 
 call Read_volume_descriptors
jmp $  
;;
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
; mov si, 0x809C 	; si = 0x8000 + 156
; mov byte dx, es:[si]
;mov byte al, es:[si + 34]
;call PrintChar16BIOS
; call PrintWordHex
; jmp $     
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
    
    ; Read the Root Directory Entry which is at offset 156 in PVD.
    mov si, 0x809c	; si = 0x8000 + 156
    mov ax, es:[si + 2] ; Logical Block Address of the extent (first 4 bytes)
    xor edx, edx
    mov dx, ax		; Save LBA
    ;call PrintWordHex
    ;jmp $
    
    ; Read the Root Directory
    mov ax, 0x0000
    mov es, ax
    mov bx, 0x9000
    
    mov eax, edx	; starting sector low 32 bit (0-indexed LBA)
    mov esi, 0		; starting sector high 32 bit
     
    mov ecx, 1		; number of sectors to read
    mov edx, 2048	; Sector sizes in bytes (1 sector = 2048 in ISO 9660)
    call ReadFromDiskUsingExtendedBIOSFunction
    
    mov si, 0x9000	; Memory Address where the Root Directory Entries (Record)
    			; is read.
   call Read_Root_Directory_Entry
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



hang:
    cli
    hlt

welcome_msg db 'Welcome to Stage1 Bootloader from ISO 9660.', 0



sLengthOfFileIdentifierStatement: db 'Length of the File Identifier is: ', 0
sDirectoryEntryPartition: db '---------------------------------------------', 0
iso_id db 'CD001'

;Times 510-($-$$) db 0
;DW 0xAA55		; Don't know why the booting works without the magic number.



bPhysicalDriveNum  db  0  ;; Used in common/disk.inc for reading disk.



Times 2048 - ($-$$) db 0	; Padding to 2KB (2048 bytes)
