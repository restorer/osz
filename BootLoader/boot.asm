; Boot sector for floppy disk (720k, FAT12) {format floppy via "format /F:720" in Win2k}
; [upd] also it work good for 1.44 floppys
;
; 1.0 - Write message
; 2.0 - It WORK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

%define KERNEL_START_SEG	0x2000

[BITS 16]
[ORG 0x7C00]

Base:		jmp short Begin
		nop

oem             db 'ProZroks'		; OEM ID
bytesPerSector  dw 0x0200		; Bytes per sector
sectPerCluster  db 0x02			; Sectors per cluster
resSectors      dw 0x01			; Reserved sectors at beginning
fatCopies       db 0x02			; Fat copies
rootEntCnt      dw 0x0070		; Root directory entries
totalSectors    dw 0x05A0		; Total sectors on disk
media           db 0xF9			; Media descriptor byte
sectPerFat      dw 0x0003		; Sectors per FAT
sectPerTrack    dw 0x0009		; Sectors per track
heads           dw 0x0002		; Heads
hiddenSectors   dd 0			; Special hidden sectors
sectorHuge      dd 0
drive           db 0			; Physical drive number
		db 0
extendedBPB     db 0x29			; Extended boot record signature
volumeID        dd 0			; Volume serial number
volumeLabel     db 'OsZ Disk   '	; Volume label
fileSys         db 'FAT12   '		; File system ID

;------------------------------------------------------------------------

Begin:		cli			; Init
		cld
		mov ax,cs
		mov ds,ax
		mov ss,ax
		mov sp,7c00h
		sti

		mov [curDrive],dl   	; get current drive from BIOS

;-----------------------------------------------

 		mov ax,$03
	   	int $10

		mov ax,$0B800
		mov es,ax
		xor di,di

		mov si,fname
		mov ah,$2F
		call Print

;-----------------------------------------------
; Get Drive Params
;-----------------------------------------------

		mov si,[hiddenSectors]
		mov di,[hiddenSectors+2]
		add si,[resSectors]
		adc di,0		; DI:SI = first FAT sector
		mov [fatStart],si
		mov [fatStart+2],di

		mov al,[fatCopies]
		xor ah,ah
		mul WORD [sectPerFat]	; DX:AX = total sectors in FATs
		add si,ax
		adc di,dx		; DI:SI = first ROOT sector
		mov [rootStart],si
		mov [rootStart+2],di

		mov ax,[rootEntCnt]
		mov cl,5		; TODO: nafiga eta stroka ?
		shl ax,5
		xor dx,dx
		div WORD [bytesPerSector]
		mov [secPerRoot],ax

		add si,ax
		adc di,0		; DI:SI = first data sector
		mov [dataStart],si
		mov [dataStart+2],di

;-----------------------------------------------
; Find File
;-----------------------------------------------

		mov ax,$1000
		mov es,ax
		mov ax,[rootStart]
		mov dx,[rootStart+2]
		mov cx,[secPerRoot]
		xor bx,bx
		call ReadSectors

		xor di,di		; ES:DI, DS:SI

FindFile0:	mov cx,11
		mov si,fname
		push di
		repe cmpsb
		pop di
		mov ax,[es:di+$1A]	; cluster number
		jz FindFile1

		add di,$20		; next dir entry
		cmp BYTE [es:di],0	; this is end of root?
		jnz FindFile0

		jmp PrintError

FindFile1:

;-----------------------------------------------
; Get FAT Chain
;-----------------------------------------------

		push ax
		mov ax,$1000
		mov es,ax
		xor bx,bx
		mov cx,[sectPerFat]
		mov ax,[fatStart]
		mov dx,[fatStart+2]
		call ReadSectors
		pop ax

		push ds		;
		push es		; swap (DS, ES)
		pop ds		;
		pop es		;
		mov di,fatBuf

GetFatChain0:	stosw		; WORD [ES:DI] = AX, DI += (DF==0)?(2):(-2)

		; use following code only for FAT12
		mov si,ax
		add si,si
		add si,ax
		shr si,1	; SI = (AX * 3) / 2, (-*-)
		lodsw		; AX = WORD [DS:SI], SI += (DF==0)?(2):(-2)
		jnc GetFatChain1	; (-*-)
		mov cl,4
		shr ax,cl
GetFatChain1:	and ah,$0F

		cmp ax,$0FF8	; This is EOC? (>= 0x0FF8)
		jc GetFatChain0

		xor ax,ax
		stosw

		push cs		; Restore DS
		pop ds

;-----------------------------------------------
; Load File
;-----------------------------------------------

		mov ax,KERNEL_START_SEG
		mov es,ax
		xor bx,bx
		mov si,fatBuf

LoadFile0:	lodsw		; AX = WORD [DS:SI], SI += (DF==0)?(2):(-2)
		and ax,ax
		jz RunemAll

		dec ax
		dec ax		; clusters numbers start from 2

		mov cl,[sectPerCluster]
		xor ch,ch
		mul cx
		add ax,[dataStart]
		adc dx,[dataStart+2]
		call ReadSectors

		push es
		mov ax,$0B800
		mov es,ax
		mov di,160
ll0:   		mov WORD [es:di], $072E
    		inc di
    		inc di
    		mov [cs:ll0-2], di
		pop es

		jmp short LoadFile0

;-----------------------------------------------

RunemAll:	mov ax,$0B800
		mov es,ax
		mov di,320
		mov si,msg_ok
		mov ah,14
		call Print

		mov dl,[drive]
		mov ax,KERNEL_START_SEG
		mov ds,ax
		mov es,ax
		jmp WORD KERNEL_START_SEG:0000

;------------------------------------------------------------------------

PrintError:    	mov si,err_notfound
		mov ax,$0B800
		mov es,ax
		mov di,160
		mov ah,$4C
		call Print

PrintError1:	jmp short PrintError1

;------------------------------------------------------------------------

; SI = szText, ES:DI = screen_address, AH = color
Print:		mov al,[cs:si]
		and al,al
		jz Print0
		mov [es:di],al
		inc di
		mov [es:di],ah
		inc di
		inc si
		jmp short Print
Print0:		ret

;------------------------------------------------------------------------

; DX:AX = first_sector_LBA, ES:BX = buffer, CX = numRead
ReadSectors:	push ax
		push dx
		push cx

		push es
		push bx
		call ReadSector
		pop bx
		pop es

		add bx,[bytesPerSector]
		jnc ReadSectors1
		mov ax,es
		add ah,$10
		mov es,ax

ReadSectors1:	pop cx
		pop dx
		pop ax

		add ax,1
		adc dx,0
		loop ReadSectors
		ret

; DX:AX = sector_LBA, ES:BX = buffer
ReadSector:	div WORD [sectPerTrack]
		inc dl			; sector = 1 + sector_LBA % sectPerTrack
		mov cl, dl     		; CL = sector

		xor dx,dx
		div WORD [heads]	; head = (sector_LBA/sectPerTrack) % heads
		mov dh,dl		; DH = head

		mov ch,al		; cyl = (sector_LBA/sectPerTrack) / heads, CH = cyl
		mov dl,[curDrive]	; DL = drive

		mov ax,$0201
		int $13
		jc PrintError
		ret

;------------------------------------------------------------------------

		;   12345678ext
fname		db "LDKERNEL   ",0
err_notfound	db "Err",0
msg_ok		db "OK",0

;------------------------------------------------------------------------
EndOfBase
		times (0x01FE-(EndOfBase-Base)) db 0
		dw 0xAA55

curDrive  	equ $		; db 0
fatStart	equ $+1		; dd 0
rootStart	equ $+5		; dd 0
secPerRoot	equ $+9		; dw 0
dataStart	equ $+11	; dd 0

fatBuf		equ $+15
