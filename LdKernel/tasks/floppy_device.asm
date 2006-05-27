%include "incl/osz.inc"
%include "incl/floppy_device.inc"
%include "incl/lowlevel.inc"

		db "OSZEXE.0"		; Executable file revision 0 id
		dd 0x1000		; Stack size
		dd _DATA_LEN		; Data size

[ORG -0x10]
[BITS 32]

		xor eax,eax
		mov [devCount],eax

Start:		mov edi,msgBuf
		mov edx,msgBuf_len
		int i_GetMessage
		jnz Process

		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_Sleep
		int i_SendMessageW
		jmp Start

Process:	cmp eax,dev_Open
		jnz Process0
		jmp OpenDevice

Process0:	cmp eax,dev_Close
		jnz Process1
		jmp CloseDevice

Process1:	cmp eax,dev_ReadSector
		jnz Process2
		jmp ReadSector
Process2:
		xor eax,eax
		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

;------------------------------------------------------------------------------------

OpenDevice:	mov eax,[devCount]
		inc eax
		mov [devCount],eax

		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

;------------------------------------------------------------------------------------

CloseDevice:	xor eax,eax
		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

;------------------------------------------------------------------------------------

ReadSector:	mov [rmRegs+krnl_RmodeInt.intNum],BYTE 0x13
		mov [rmRegs+krnl_RmodeInt.r_es],WORD RMODE_SPACE_SEG
		mov [rmRegs+krnl_RmodeInt.r_bx],WORD 0
		mov al,[drive]
		mov [rmRegs+krnl_RmodeInt.r_dl],al
		mov [rmRegs+krnl_RmodeInt.r_ax],WORD 0x0201

		xor edx,edx
		mov eax,[msgBuf+sdev_ReadSector.sectorL]
		div DWORD [sectPerTrack]
 		inc dl					; sector = 1 + sector_LBA % sectPerTrack
		mov [rmRegs+krnl_RmodeInt.r_cl],dl	; CL = sector
 		xor edx,edx
		div DWORD [heads]			; head = (sector_LBA/sectPerTrack) % heads
		mov [rmRegs+krnl_RmodeInt.r_dh],dl	; DH = head
 		mov [rmRegs+krnl_RmodeInt.r_ch],al	; cyl = (sector_LBA/sectPerTrack) / heads, CH = cyl

		mov eax,msg_RmodeInt
		xor ebx,ebx
		mov esi,rmRegs
		mov ecx,krnl_RmodeInt.msize
		mov edi,esi
		mov edx,ecx
		int i_SendMessageW

		movzx eax,WORD [rmRegs+krnl_RmodeInt.r_flags]
		test eax,CF_OR
		jz ReadSector1

		; read error
		mov ecx,511
		mov esi,sec
		mov edi,sec+1
		mov [esi],BYTE 0
		rep movsb
		jmp ReadSector2

ReadSector1:	mov ecx,512
		mov esi,RMODE_SPACE
		mov edi,sec

ReadSector0:	mov eax,[gs:esi]
		stosd
		add esi,4
		loop ReadSector0

ReadSector2:	mov esi,sec
		mov ecx,512
		int i_ProcessMessage
		jmp Start

;------------------------------------------------------------------------------------

drive		db 0
sectPerTrack	dd 18		; only for 1'44
heads		dd 2

;------------------------------------------------------------------------------------
;;;; DATA
;------------------------------------------------------------------------------------
_DATA_START	equ $

rmRegs		equ _DATA_START
_end_rmRegs	equ rmRegs+krnl_RmodeInt.msize

devCount	equ _end_rmRegs
_end_devCount	equ devCount+4

msgBuf		equ _end_devCount
msgBuf_len	equ 0x100
_end_msgBuf	equ msgBuf+msgBuf_len

sec		equ _end_msgBuf
_end_sec	equ sec+512

_DATA_LEN	equ _end_sec-_DATA_START
