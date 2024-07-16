%ifndef __ISO_9660_INC__
%define __ISO_9660_INC__

%define VOLUME_DESCRIPTOR_READ_LOCATION 0x0500;0x8000
%define FILE_LOADING_AREA 0xB000

Read_volume_descriptors:
	pushad 		; save the state
	mov si, sReadingVolumeDescriptorsStatement
	call PrintString16BIOS
	call PrintNewline
.iterate_descriptor:
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
     mov cx, 5		; 5 characters to check
     mov di, iso_id
     repe cmpsb
     jne .invalid_iso_disk

    ;; We got the valid iso disk identifier.
    ; Print valid iso disk statement.
    push si
    mov si, sValidISODiskIdentifierString
    call PrintString16BIOS
    call PrintNewline
    pop si
    
    ;; Location where the descriptor was read, load it in al.
    mov byte al, [VOLUME_DESCRIPTOR_READ_LOCATION]
    
    ; Print the Volume Descriptor Type
    mov si, sVolumeDescriptorTypeStatement
    call PrintString16BIOS
    call PrintWordNumber
    call PrintNewline
    
    ; Check if the descriptor is Primary Volume Descriptor.
    cmp al, 0x01	; Check for the Primary Volume Descriptor (PVD)
    jne .read_next_volume_descriptor	; If not PVD, read next descriptor
    
    ;; Got PVD
    ; Print the PVD statement
    mov si, sGotPVDStatement
    call PrintString16BIOS
    call PrintNewline

    ;; Read the Root Directory Entry from the PVD,
    ;; which is at offset 156.
    ;; Root Directory Entry is of 34 bytes.
    mov si, VOLUME_DESCRIPTOR_READ_LOCATION
    add si, 156		; Offset 156, where the Root Directory Entry Structure is located.
;    mov si, 0x809c	; si = 0x8000 + 156
    mov dword eax, es:[si + 2] ; Logical Block Address of the extent (first 4 bytes)
    xor edx, edx
    mov edx, eax		; Save LBA

    ;; Read the Root Directory Entry at Location 0x9000
    mov ax, 0x0000
    mov es, ax
    mov bx, 0x9000
    
    mov eax, edx	; starting sector low 32 bit (0-indexed LBA)
    mov esi, 0		; starting sector high 32 bit
     
    mov ecx, 1		; number of sectors to read
    mov edx, 2048	; Sector sizes in bytes (1 sector = 2048 in ISO 9660)
    call ReadFromDiskUsingExtendedBIOSFunction

    ;; Read Root Directory Entry and Print its Entries Identifier.
    mov si, 0x9000	; Memory Address where the Root Directory Entries (Record)
    			; is read.
    call Find_and_Load_File_from_Root
;    call Read_Root_Directory_Entry
   jmp .done_reading_volume_descriptor	; We are done reading and printing root directory entries.

;; Read the very next volume decriptor.
.read_next_volume_descriptor:
    cmp al, 0xFF			; Check for the end of volume descriptor list
    					; which is Volume Descriptor Set Terminator
    					; whose type (first byte) is 0xFF.
    je .volume_descriptor_terminator

    add dword [dwVolumeDescriptorStartingSector], 1	; read next sector i.e next volume descriptor.
    jmp .iterate_descriptor


;; Volume Descriptor Set Terminator
.volume_descriptor_terminator:
   mov si, volume_descriptor_terminator_encountered
   call PrintString16BIOS		

.done_reading_volume_descriptor:
	popad		; restore the state
ret

.invalid_iso_disk:
    ;; We got the Invalid ISO DISK
    ; Print the invalid statement and go to infinite loop
    mov si, invalid_iso_disk_statement
    call PrintString16BIOS
    call PrintNewline
jmp $


; **************************
; Reads the Root Directory Entry which should be pointed
; by `SI`. It scans all the entries of the root directory
; and prints the identifier(name) of one and all.
; IN:
; 	- SI Root Directory Entry
; **************************
Read_Root_Directory_Entry:
	pushad		; save the state
.iterate_entry:
	xor ax, ax		; Clear out the ax register
	mov byte al, es:[si]	; it points to the 0 offset in directory entry.
				; At Offset 0 is length of the record.
				; It should be non zero, if zero means no valid record.
	test al, al
	
	jz .reading_done
	
	;; It is valid directory record.


	xor cx, cx
	xor dx, dx
	;mov cx, 10
	mov byte cl, es:[si + 32]	; get the file identifier length.
	mov byte dx, cx
	call PrintWordHex
	call PrintNewline
	mov di, si		; di and si both contains the current directory entry.
	add di, 33		; Add 33 to di which is the starting of
				; file identifier of the current directory entry.
.print_entries_identifier_char:
	mov byte al, es:[di]	; read the first character of current directory
				; entry's file identifier.
	call PrintChar16BIOS
	inc di			; jmp to next char in file identifier.
	loop .print_entries_identifier_char	; loop to print next char.
	call PrintNewline	; '\n'
	add byte si, es:[si]	; jump to next directory entry by adding
				; the length of the current directory entry.
	jmp .iterate_entry

.reading_done:
	popad 	; restore the state
ret



dwVolumeDescriptorStartingSector dd 16	;; starting sector where the volume descriptor resides.

invalid_iso_disk_statement: db 'Invalid ISO disk identifier.', 0
volume_descriptor_terminator_encountered: db 'Volume Descriptor Set Terminator Encountered.', 0
sReadingVolumeDescriptorsStatement: db 'Reading Volume Descriptors...', 0
sValidISODiskIdentifierString: db 'It`s valid ISO Disk Identifier.', 0
sVolumeDescriptorTypeStatement: db 'Volume Descriptor Type = ', 0
sGotPVDStatement: db 'We got the PVD.', 0

;sItsDirectoryStatement: db 'Its a directory.', 0
iso_id db 'CD001'
%endif
