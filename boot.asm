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

; **************************
; Reads the Root Directory Entry which should be pointed
; by `SI`. It scans all the entries of the root directory
; and prints the identifier(name) of one and all.
; IN:
; 	- SI Root Directory Entry
; **************************
Find_and_Load_File_from_Root:
	pusha		; save the state
;	push bp		; Save old base pointer
;	mov bp, sp	; Set new base pointer
;	sub sp, 16	; Allocate 16 bytes for local variables
.iterate_entry:

	xor ax, ax		; Clear out the ax register
	mov byte al, es:[si]	; it points to the 0 offset in directory entry.
				; At Offset 0 is length of the record.
				; It should be non zero, if zero means no valid record.
	test al, al
	
	jz .reading_done
	
	;; It is valid directory record.

	; Get the File Flags field (offset 25 from the start of the entry).
	mov byte al, [si + 25]
	; Check if it's a directory
	test al, 0x02	; Check if bit 1 is set
	jnz .is_directory

	;; It is a file
	
	;; Check it's identifier.
	xor cx, cx
	xor dx, dx
	;mov cx, 10
	mov byte cl, es:[si + 32]	; get the file identifier length.
	mov byte dx, cx
	;call PrintWordHex
	;call PrintNewline
	cmp byte es:[si + 33], 'A'	; Compare file name 'a'
	jne .onto_next

	cmp byte es:[si + 34], 'B'
	jne .onto_next
	
	cmp byte es:[si + 35], '.'	; Compare file name 'a'
	jne .onto_next

	cmp byte es:[si + 36], 'T'
	jne .onto_next
	
	cmp byte es:[si + 37], 'X'	; Compare file name 'a'
	jne .onto_next

	cmp byte es:[si + 38], 'T'
	jne .onto_next
	
	;; got the file
    mov ax, es:[si + 2] ; Logical Block Address of the extent (first 4 bytes)
    xor edx, edx
    mov dx, ax		; Save LBA
    
    mov ax, 0x0000
    mov es, ax
    mov bx, FILE_LOADING_AREA;0x0500
    
    mov byte ax, [si+ 10]
;   add eax, 2047
;   mov ecx, 2048
;   div ecx
;   mov ecx, eax
 ;  call PrintWordNumber
   ;jmp $
 ;   mov ecx, (ecx + 2047)/2048
    mov eax, edx	; starting sector low 32 bit (0-indexed LBA)
    mov esi, 0		; starting sector high 32 bit
    
    mov ecx, 1		; number of sectors to read
    mov edx, 2048	; Sector sizes in bytes (1 sector = 2048 in ISO 9660)
    call ReadFromDiskUsingExtendedBIOSFunction
mov si, FILE_LOADING_AREA;0x0500
lodsb


;mov al, 'r'
mov ah, 0x0e
int 0x10
jmp $
    jmp $
	
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

.is_directory:
	; handle the directory, for the time being, just jump to next entry.
	;push si
	;mov si, sItsDirectoryStatement
	;call PrintString16BIOS
	;call PrintNewline
	;pop si
.onto_next:
	add byte si, es:[si]	; increment si to point to next entry
	jmp .iterate_entry

.reading_done:
;	mov sp, bp	; Reset Stack pointer
;	pop bp		; Restore old base pointer
	popa 	; restore the state
ret


hang:
    cli
    hlt

;section .data
welcome_msg db 'Welcome to Stage1 Bootloader from ISO 9660.', 0



sLengthOfFileIdentifierStatement: db 'Length of the File Identifier is: ', 0
;sDirectoryEntryPartition: db '-------------------------------------', 0
sDirectoryEntryPartition: db '--------------------------------------', 0
sUnpaddedSizeStatement: db 'Un-Padded Size of Bootloader (bytes): ', 0

;Times 510-($-$$) db 0
;DW 0xAA55		; Don't know why the booting works without the magic number.



bPhysicalDriveNum  db  0  ;; Used in common/disk.inc for reading disk.


;; Mark of unpadded end.
end:

Times 2048 - ($-$$) db 0	; Padding to 1KB (1024 bytes)
