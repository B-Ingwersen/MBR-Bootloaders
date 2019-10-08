[bits 16]
[org 0x7c00]	; offsets by start of memory location

jmp bootCode
nop

oemIdentifier:      times 8 db 0
bytesPerSector:     dw 0
sectorsPerCluster:  db 0
nReservedSectors:   dw 0
nFATS:              db 0
nDirectoryEntries:  dw 0
totalSectors:       dw 0
mediaDescriptType:  db 0
fat1216SecsPerFAT:  dw 0
sectorsPerTrack:    dw 0
headsInMedia:       dw 0
partitionBaseAddress:
nHiddenSectors:     dd 0
largeSectorCount:   dd 0

sectorsPerFAT:      dd 0
flagsOffset:        dw 0
FATVersionNumber:   dw 0
rootDirClusterNum:  dd 0
fsInfoSector:       dw 0
backupBootSector:   dw 0
reservedBytes12:    times 12 db 0
driveNumber:        db 0
windowsNTFlags:     db 0
signature:          db 0
volumeID:           dd 0
volumeLabel:        times 11 db 0
identifierString:   times 8 db 0

mov [saveBootDrive], dl

bootCode:
    mov ax, 0x03			; ensure 80x25 text mode
    int 0x10

    xor eax, eax
    mov es, ax
    mov ss, ax
    mov ds, ax
    mov fs, ax
    mov gs, ax

    setUpBootLoaderStack:
        mov sp, 0x8000		; sets up the stack at 0x8000
        mov bp, sp

    xor eax, eax
    mov edx, eax
    mov ax, [bytesPerSector]
    shr ax, 9
    mov [sectorSize], eax
    mul byte [sectorsPerCluster]
    mov [clusterSize], eax

    mov eax, [sectorsPerFAT]
    mov dl, [nFATS]
    mul edx
    mov dx, [nReservedSectors]
    add eax, edx
    mov dx, [sectorSize]
    mul edx
    mov [firstDataSector], eax

.loadTheBootFile:
    mov eax, [rootDirClusterNum]
    mov si, bootDirectoryFileName
    call findBootInClusterChain
    mov si, bootFileFileName
    call findBootInClusterChain
    call loadCluster

    mov dl, [saveBootDrive]

    jmp 0x0000:0x8000

findBootInClusterChain:                             ; esi = string
    call loadCluster
    xor bx, bx

    checkFileNames:
        mov ecx, [si]
        cmp [bx + 0x8000], ecx
        jne .noMatch
        mov ecx, [si + 4]
        cmp [bx + 0x8004], ecx
        jne .noMatch
        mov ecx, [si + 7]
        cmp [bx + 0x8007], ecx
        jne .noMatch

        jmp foundFileName

        .noMatch:
        add bx, 32

        mov cx, bx
        shr cx, 9
        cmp cx, [clusterSize]
        je endOfCluster

        jmp checkFileNames
    
    endOfCluster:
        mov ebx, eax
        shl ebx, 2                                  ; multiply by 4 for offset in table

        xor eax, eax
        mov ax, [nReservedSectors]
        mul word [sectorSize]
        
        mov ecx, ebx
        shr ecx, 9
        add eax, ecx
        add eax, [partitionBaseAddress]
        call loadDisk
        
        and bx, 0x1FF
        mov eax, [bx + 0x8000]

        cmp eax, 0x0FFFFFF7
        jae Fail
        
        jmp findBootInClusterChain

    foundFileName:
        mov ax, [bx + 0x8000 + 20]
        shl eax, 16
        mov ax, [bx + 0x8000 + 26]
        ret
    
Fail:

    xor bx, bx
    mov ax, 0x0E00 + 'E'
    int 0x10
    mov ax, 0x0E00 + 'R'
    int 0x10
    mov ax, 0x0E00 + 'R'
    int 0x10
    mov ax, 0x0E00 + 'O'
    int 0x10
    mov ax, 0x0E00 + 'R'
    int 0x10

    mov ah, 0
    int 0x16

    codeRelocation:
        mov si, 0x7C00
        mov di, 0x1000
        mov cx, 512
        rep movsb

        jmp relocationJump + 0x1000 - 0x7C00

    relocationJump:
        xor eax, eax
        call loadDisk
        
        mov si, 0x8000
        mov di, 0x7C00
        mov cx, 512
        rep movsb

        mov dl, [saveBootDrive]
        mov eax, [0x7C00]
        jmp 0:0x7C00

loadCluster:                        ; eax = clusterNumber
    pusha
    sub eax, 2
    mov edx, eax
    mov eax, [clusterSize]
    mul edx
    add eax, [firstDataSector]
    add eax, [partitionBaseAddress]
    
    call loadDisk

    popa
    ret


loadDisk:                           ; eax=sector, always loads 1 clusters worth of data
    pusha

    mov [loadSector], eax
    mov [loadToLocation], word 0x8000
    mov ax, [clusterSize]
    mov [loadSizeSectors], ax

    mov si, DiskAddressPacket
    mov dl, [saveBootDrive]
    mov ah, 0x42

    int 0x13

    popa
    ret

bootDirectoryFileName:
    db "BOOT       "
bootFileFileName:
    db "FAT32MBR   "

times 0x1F0 - 16 - ($-$$) db 0

DiskAddressPacket:
    db 0x10
    db 0
    loadSizeSectors:
    dw 1
    loadToLocation:
    dw 0
    dw 0
    loadSector:
    dd 0
    dd 0

times 510 - ($-$$) db 0
db 0x55
db 0xAA

saveBootDrive:      db 0
clusterSize:        dd 0            ; in sectors
sectorSize:         dd 0            ; in sectors
firstDataSector:    dd 0

