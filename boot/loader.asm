org 0100h

jmp LABEL_START

%include "fat12hdr.inc"
%include "pm.inc"
%include "load.inc"

LABEL_GDT:          Descriptor          0,              0,                      0
LABEL_DESC_FLAT_C:  Descriptor          0,    0fffffh   ,DA_CR|DA_32|DA_LIMIT_4K
LABEL_DESC_FLAT_RW: Descriptor           0,    0fffffh  ,DA_DRW|DA_32|DA_LIMIT_4K
LABEL_DESC_VIDEO:   Descriptor     0b8000h,     0ffffh  ,DA_DRW|DA_DPL3

GdtLen      equ     $-LABEL_GDT
GdtPtr      dw     GdtLen-1
dd LOADER_PHY_ADDR+LABEL_GDT

SelectorFlatC     equ     LABEL_DESC_FLAT_C-LABEL_GDT
SelectorFlatRW    equ     LABEL_DESC_FLAT_RW-LABEL_GDT
SelectorVideo     equ     LABEL_DESC_VIDEO-LABEL_GDT+SA_RPL3

BaseOfStack         equ         0100h


LABEL_START:
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,BaseOfStack


    mov dh,0
    call DispStrRealMode

    mov	ebx, 0
    mov	di, _MemChkBuf
.MemChkLoop:
    mov	eax, 0E820h
    mov	ecx, 20
    mov	edx, 0534D4150h	
    int	15h
    jc	.MemChkFail
    add	di, 20
    inc	dword [_dwMCRNumber]
    cmp	ebx, 0
    jne	.MemChkLoop
    jmp	.MemChkOK
.MemChkFail:
	mov	dword [_dwMCRNumber], 0
.MemChkOK:
    mov word [wSectorNo],SectorNoOfRootDirectory
    xor ah,ah
    xor dl,dl
    int 13h

LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
    cmp word [wRootDirSizeForLoop],0
    jz LABEL_NO_KERNELBIN
    dec word [wRootDirSizeForLoop]
    mov ax,KERNEL_FILE_SEG
    mov es,ax
    mov bx,KERNEL_FILE_OFF
    mov ax,[wSectorNo]
    mov cl,1
    call ReadSector ;0x7d54
    
    mov si,KernelFileName
    mov di,KERNEL_FILE_OFF
    cld
    mov dx,10h

LABEL_SEARCH_FOR_KERNELBIN:
    cmp dx,0
    jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
    dec dx
    mov cx,11
LABEL_CMP_FILENAME:
    cmp cx,0
    jz LABEL_FILENAME_FOUND
    dec cx
    lodsb
    cmp al,byte [es:di]
    jz LABEL_GO_ON
    jmp LABEL_DIFFERENT
LABEL_GO_ON:
    inc di
    jmp LABEL_CMP_FILENAME
LABEL_DIFFERENT:
    and di,0FFE0H
    add di,20h
    mov si,KernelFileName
    jmp LABEL_SEARCH_FOR_KERNELBIN
LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
    add word [wSectorNo],1
    jmp LABEL_SEARCH_IN_ROOT_DIR_BEGIN
LABEL_NO_KERNELBIN:
    mov dh,2
    call DispStrRealMode
    jmp $
LABEL_FILENAME_FOUND:
    mov ax,RootDirSectors
    and di,0FFF0h

    push eax
    mov eax,[es:di+01Ch]
    mov dword [dwKernelSize],eax
    pop eax

    add di,01Ah
    mov cx, word [es:di]
    push cx
    add cx,ax
    add cx,DeltaSectorNo
    mov ax,KERNEL_FILE_SEG
    mov es,ax
    mov bx,KERNEL_FILE_OFF
    mov ax,cx
    
LABEL_GOON_LOADING_FILE:
    push ax
    push bx
    mov ah,0Eh
    mov al,'.'
    mov bl,0Fh
    int 10h
    pop bx
    pop ax
    
    mov cl,1
    call ReadSector
    pop ax
    call GetFATEntry
    cmp ax,0FFFh
    jz LABEL_FILE_LOADED
    push ax
    mov dx,RootDirSectors
    add ax,dx
    add ax,DeltaSectorNo
    add bx,[BPB_BytsPerSec]
    jc .1
    jmp .2

.1:
    push ax
    mov ax,es
    add ax,1000h
    mov es,ax
    pop ax

.2:
    jmp LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:
    call KillMotor
    mov dh,1
    call DispStrRealMode
   
    lgdt [GdtPtr]
   
    cli
    
    in al,92h
    or al,00000010b
    out 92h,al


    mov eax,cr0
    or eax,1
    mov cr0,eax
  


    jmp dword SelectorFlatC:(LOADER_PHY_ADDR+LABEL_PM_START)
    

wRootDirSizeForLoop         dw      RootDirSectors
wSectorNo                   dw      0
bOdd                        db      0
dwKernelSize                dd      0

KernelFileName              db      "KERNEL  BIN",0
MessageLength               equ     9
LoadMessage:                db      "Loading  "
Message1                    db      "Ready LD."
Message2                    db      "NO KERNEL"
Message3                    db      "TestMsg.."

DispStrRealMode:
    mov ax,MessageLength
    mul dh
    add ax,LoadMessage
    mov bp,ax
    mov ax,ds
    mov es,ax
    mov cx,MessageLength
    mov ax,01301h
    mov bx,0007h
    mov dl,0
    add dh,3
    int 10h
    ret

ReadSector:
    push bp
    mov bp,sp
    sub esp,2
    mov byte [bp-2],cl
    push bx
    mov bl,[BPB_SecPerTrk]
    div bl
    inc ah
    mov cl,ah
    mov dh,al
    shr al,1
    mov ch,al
    and dh,1
    pop bx
    mov dl,[BS_DrvNum]
.GoOnReading:
    mov ah,2
    mov al,byte [bp-2]
    int 13h
    jc .GoOnReading

    add esp,2
    pop bp
    ret

GetFATEntry:
    push es
    push bx
    push ax
    mov ax,KERNEL_FILE_SEG
    sub ax,0100h
    mov es,ax
    pop ax
    mov byte [bOdd],0
    mov bx,3
    mul bx
    mov bx,2
    div bx
    cmp dx,0
    jz LABEL_EVEN
    mov byte [bOdd],1
LABEL_EVEN:
    xor dx,dx
    mov bx,[BPB_BytsPerSec]
    div bx
    push dx
    mov bx,0
    add ax,SectorNoOfFAT1
    mov cl,2
    call ReadSector

    pop dx
    add bx,dx
    mov ax,[es:bx]
    cmp byte [bOdd],1
    jnz LABEL_EVEN_2
    shr ax,4
LABEL_EVEN_2:
    and ax,0fffh

LABEL_GET_FAT_ENTRY_OK:
    pop bx
    pop es
    ret
KillMotor:
	push	dx
	mov	dx, 03F2h
	mov	al, 0
	out	dx, al
	pop	dx
	ret

[SECTION .s32]

ALIGN 32
[BITS 32]

LABEL_PM_START:
    mov ax,SelectorVideo
    mov gs,ax

    mov ax,SelectorFlatRW
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov ss,ax
    mov esp,TopOfStack

    ;call Debu

    call DispMemInfo
    call SetupPaging
    call InitKernel

    mov dword [BOOT_PARAM_ADDR], BOOT_PARAM_MAGIC
    mov eax, [dwMemSize]
    mov [BOOT_PARAM_ADDR + 4], eax
    mov eax, KERNEL_FILE_SEG
    shl eax, 4
    add eax, KERNEL_FILE_OFF
    mov [BOOT_PARAM_ADDR + 8], eax

    jmp SelectorFlatC:KRNL_ENT_PT_PHY_ADDR

%include "lib.inc"

DispMemInfo:
    push esi
    push edi
    push ecx

    mov	esi, MemChkBuf
    mov	ecx, [dwMCRNumber]
.loop:
    mov	edx, 5
    mov	edi, ARDStruct
.1:
    push dword [esi]
    pop	eax
    stosd
    add	esi, 4
    dec	edx
    cmp	edx, 0
    jnz	.1
    cmp	dword [dwType], 1
    jne	.2
    mov	eax, [dwBaseAddrLow];
    add	eax, [dwLengthLow];
    cmp	eax, [dwMemSize]
    jb	.2
    mov	[dwMemSize], eax
.2:
    loop	.loop

    call DispReturn
    push szRAMSize
    call DispStr
    add	esp, 4

    push dword [dwMemSize]
    call DispInt
    add	esp, 4

    pop	ecx
    pop	edi
    pop	esi
    ret

SetupPaging:
    xor edx,edx
    mov eax,[dwMemSize]
    mov ebx,400000h
    div ebx
    mov ecx,eax
    test edx,edx
    jz .no_remainder
    inc ecx
.no_remainder:
    push ecx
    mov ax,SelectorFlatRW
    mov es,ax
    mov edi,PAGE_DIR_BASE
    xor eax,eax
    mov eax,PAGE_TBL_BASE|PG_P|PG_USU|PG_RWW
.1:
    stosd
    add eax,4096
    loop .1
    
    pop eax
    mov ebx,1024
    mul ebx
    mov ecx,eax
    mov edi,PAGE_TBL_BASE
    xor eax,eax
    mov eax,PG_P|PG_USU|PG_RWW
.2:
    stosd
    add eax,4096
    loop .2

    mov eax,PAGE_DIR_BASE
    mov cr3,eax
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax
    jmp short .3
.3:
    nop
    ret

InitKernel:
    xor	esi, esi
    mov	cx, word [KERNEL_FILE_PHY_ADDR + 2Ch]
    movzx	ecx, cx
    mov	esi, [KERNEL_FILE_PHY_ADDR + 1Ch]
    add	esi, KERNEL_FILE_PHY_ADDR
.Begin:
    mov	eax, [esi + 0]
    cmp	eax, 0
    jz	.NoAction
    push dword [esi + 010h]
    mov	eax, [esi + 04h]
    add	eax, KERNEL_FILE_PHY_ADDR
    push eax
    push dword [esi + 08h]
    call MemCpy
    add	esp, 12
.NoAction:
    add	esi, 020h
    dec	ecx
    jnz	.Begin

    ret

Debu:
    push szTestMessage
    call DispStr
    add esp,4
    ret

[SECTION .data1]

ALIGN	32

LABEL_DATA:
_szMemChkTitle:	db "BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0
_szRAMSize:	db "RAM size:", 0
_testMessage:   db "In Protect Mod Now",0ah,0
_szReturn:	db 0Ah, 0

_dwMCRNumber:	dd 0
_dwDispPos:	dd (80 * 6 + 0) * 2
_dwMemSize:	dd 0
_ARDStruct:
  _dwBaseAddrLow:		dd	0
  _dwBaseAddrHigh:		dd	0
  _dwLengthLow:			dd	0
  _dwLengthHigh:		dd	0
  _dwType:			dd	0
_MemChkBuf:	times	256	db	0

szMemChkTitle		equ	LOADER_PHY_ADDR + _szMemChkTitle
szRAMSize		equ	LOADER_PHY_ADDR + _szRAMSize
szTestMessage           equ     LOADER_PHY_ADDR + _testMessage
szReturn		equ	LOADER_PHY_ADDR + _szReturn
dwDispPos		equ	LOADER_PHY_ADDR + _dwDispPos
dwMemSize		equ	LOADER_PHY_ADDR + _dwMemSize
dwMCRNumber		equ	LOADER_PHY_ADDR + _dwMCRNumber
ARDStruct		equ	LOADER_PHY_ADDR + _ARDStruct
	dwBaseAddrLow	equ	LOADER_PHY_ADDR + _dwBaseAddrLow
	dwBaseAddrHigh	equ	LOADER_PHY_ADDR + _dwBaseAddrHigh
	dwLengthLow	equ	LOADER_PHY_ADDR + _dwLengthLow
	dwLengthHigh	equ	LOADER_PHY_ADDR + _dwLengthHigh
	dwType		equ	LOADER_PHY_ADDR + _dwType
MemChkBuf		equ	LOADER_PHY_ADDR + _MemChkBuf


    StackSpace times 1024       db      0
    TopOfStack                  equ     LOADER_PHY_ADDR+$
