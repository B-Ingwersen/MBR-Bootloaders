[bits 16]
[org 0x7c00]	; offsets by start of memory location

start:
    xor eax, eax
    mov es, ax
    mov ss, ax
    mov ds, ax
    mov fs, ax
    mov gs, ax

    mov ax, 0x03			; ensure 80x25 text mode
    int 0x10

    setUpBootLoaderStack:
        mov sp, 0x8000		; sets up the stack at 0x8000
        mov bp, sp

mov [saveBootDrive], dl

mov ax, 0x03			; ensure 80x25 text mode
int 0x10

mov cx, 26
call print_spaces

mov di, string3
mov cl, 27
call print_string_length

call newLine
call newLine

mov cl, 16
call print_spaces
mov di, string2
mov cl, 41
call print_string_length

call newLine

mov bx, 0x1BE + LOAD_LOCATION + 8
mov si, 0
goThroughPartitionList:
    mov eax, [bx]
    test eax, eax
    je .noEntry

    call loadFromDisk

    mov cl, 16
    call print_spaces

    mov di, string1 + 1
    mov cl, 6
    call print_string_length

    mov ax, si
    add al, '1'
    call print_char

    dec di
    call print_string_length

    call print_hex
    add bx, 4

    mov di, string1 + 1
    mov cl, 2
    call print_string_length

    call print_hex
    sub bx, 4

    call print_string_length

    .fat32Check:
        pusha

        mov al, [bx - 4]
        cmp al, 0xB
        je .isFat32
        cmp al, 0xC
        je .isFat32
        jmp .notFat32

        .isFat32:
            mov di, [loadLocation]
            add di, 0x47 - 512
            mov cx, 11
            call print_string_length

        .notFat32:
        popa

    inc si
    call newLine

    .noEntry:

    add bx, 16
    cmp bx, LOAD_LOCATION + 0x1FE
    jb goThroughPartitionList

keyboardLoop:
    mov ah, 0
    int 16h

    sub al, '1'
    mov ah, 0
    cmp ax, si
    jae keyboardLoop

codeRelocation:
    mov si, 0x7C00
    mov di, 0x1000
    mov cx, 512
    rep movsb

    jmp relocationJump + 0x1000 - 0x7C00

relocationJump:
    
    shl ax, 9
    add ax, 0x2000
    mov si, ax
    mov di, 0x7C00
    mov cx, 512
    rep movsb

    mov eax, [0x7C00]
    jmp 0:0x7C00


;PRINT SERVICES
    print_char:
        mov ah, 0x0e
        int 0x10		; uses BIOS interupt to print character in al
        ret

    print_string_length:	;prints the value specified at bx
        pusha
        .loop:
            mov al, [di]		; moves the next character into al
            call print_char		; character in al is printed
            inc di			; moves bx to next address in memory; next character in the string
            loop .loop		; goes back to the beginning of the loop
        .end:		; ends the function
            popa
            ret

    newLine:
        mov ah, 0x0E
        mov al, 0x0a	; adds a space for asthetics
        int 0x10
        mov al, 0x0d	; adds a space for asthetics
        int 0x10
        ret
    
    print_hex:	; prints word at address in bx in hexidecimal
        pusha

        mov al, '0'
        call print_char
        mov al, 'x'
        call print_char

        mov edx, [bx]
        mov cx, 8
        .loop:
            mov eax, edx
            shr eax, 28
            add al, 0x30
            cmp al, 0x3A
            jb .isHexNumeral
            add al, 0x07
            .isHexNumeral:
            call print_char
            shl edx, 4
            loop .loop

        popa
        ret
    
    print_spaces:
        .loop:
            mov al, ' '
            call print_char
            loop .loop
        ret

;PRINT SERVICES

loadFromDisk:       ; eax is base sector
    pusha

    mov [loadSector], eax

    mov ax, [loadLocation]
    mov [loadToLocation],ax

    mov si, DiskAddressPacket
    mov dl, [saveBootDrive]
    mov ah, 0x42

    int 0x13

    mov ax, [loadLocation]
    add ax, 512
    mov [loadLocation], ax

    popa

    ret



loadLocation:
    dd 0x2000

DiskAddressPacket:
    db 0x10
    db 0
    dw 1
    loadToLocation:
    dw 0
    dw 0
    loadSector:
    dd 0
    dd 0

string1:
    db ")     ("
string2:
    db "Partition#   Start/512   Length/512  Name"
string3:
    db "Select Partition (keys 1-4)"

times 510 - ($-$$) db 0
db 0x55
db 0xAA

saveBootDrive:
    db 0

LOAD_LOCATION equ 0x7C00