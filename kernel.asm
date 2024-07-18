BITS 16		; 16-bit code
ORG 0xB000	; Origin set to 0xB000

; Print welcome message
mov si, sKernelEntryWelcomeStatement  ; Load offset of the welcome message
cld                                   ; Clear direction flag for forward string operations

print_loop:
    lodsb                              ; Load byte at [SI] into AL, increment SI
    test al, al                          ; Compare AL with null terminator
    jz print_done                     ; If null terminator, jump to end
    mov ah, 0x0e                       ; Set AH for teletype output
    int 0x10                           ; BIOS interrupt to print character in AL
    jmp print_loop                    ; Repeat loop

print_done:
jmp $                                 ; Infinite loop to halt CPU

sKernelEntryWelcomeStatement: db 'Welcome to Binary Kernel', 0  ; Welcome message with null terminator

; Pad remaining space to 2 KB sector size
Times 2048 - ($ - $$) db 0

