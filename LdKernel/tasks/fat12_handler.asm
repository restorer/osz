%include "incl/osz.inc"
%include "incl/macro.inc"
%include "incl/floppy_device.inc"
%include "incl/fat12_handler.inc"
%include "incl/console_library.inc"

		struc s_bs
.jmpBoot	resb 3
.oem		resb 8
.bytesPerSector	resw 1			; Bytes per sector
.sectPerCluster	resb 1			; Sectors per cluster
.resSectors	resw 1			; Reserved sectors at beginning
.fatCopies	resb 1			; Fat copies
.rootEntCnt	resw 1			; Root directory entries
.totalSectors	resw 1			; Total sectors on disk
.media		resb 1			; Media descriptor byte
.sectPerFat	resw 1			; Sectors per FAT
.sectPerTrack	resw 1			; Sectors per track
.heads		resw 1			; Heads
.hiddenSectors	resd 1			; Special hidden sectors
.sectorHuge	resd 1
.drive		resb 1			; Physical drive number
		resb 1
.extendedBPB	resb 1			; Extended boot record signature
.volumeID	resd 1			; Volume serial number
.volumeLabel	resb 11			; Volume label
.fileSys	resb 8			; File system ID
.msize
		endstruc

%define MAX_BLOCK_SIZE 0x1000
%define MAX_FILES 32
%define MODE_READ 1
%define MODE_WRITE 2

		struc s_file
.mode		resb 1
.dir_entry	resw 1
.cluster	resw 1
.fsize		resd 1
.position	resw 1
.data		resb 512
.msize
		endstruc


		db "OSZEXE.0"		; Executable file revision 0 id
		dd 0x1000		; Stack size
		dd _DATA_LEN		; Data size

[ORG -0x10]
[BITS 32]

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

Process:	cmp eax,hndl_Init
		jnz Process0
		jmp Init

Process0:	cmp eax,hndl_Destroy
		jnz Process1
		jmp Destroy

Process1:	cmp eax,hndl_ReadFile
		jnz Process2
		jmp ReadFile

Process2:	cmp eax,hndl_GetFileSize
		jnz Process3
		jmp GetFileSize

Process3:	cmp eax,hndl_Read
		jnz Process4
		jmp Read

Process4:	cmp eax,hndl_CloseFile
		jnz Process5
		jmp CloseFile

Process5:
Ok:		xor eax,eax
Err:		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

;--------------------------------------------------------------------------------------------

Init:		mov eax,[devTaskID]
		and eax,eax
		jz Init0

		xor eax,eax
		jmp Err

Init0:		mov eax,[msgBuf+shndl_Init.devTaskID]
		mov [devTaskID],eax
		mov eax,[msgBuf+shndl_Init.deviceID]
		mov [deviceID],eax

		;;;;

		mov eax,[deviceID]
		mov [msgBuf+sdev_ReadSector.deviceID],eax
		xor eax,eax
		mov [msgBuf+sdev_ReadSector.sectorL],eax
		mov [msgBuf+sdev_ReadSector.sectorH],eax

		mov ebx,[devTaskID]
		mov eax,dev_ReadSector
		mov esi,msgBuf
		mov ecx,sdev_ReadSector.msize
		mov edi,bootSect
		mov edx,512
		int i_SendMessageW

		;;;;

		mov ebx,[bootSect+s_bs.hiddenSectors]
		movzx ecx,WORD [bootSect+s_bs.resSectors]
		add ebx,ecx
		mov [fatStart],ebx		; first FAT sector

		movzx eax,BYTE [bootSect+s_bs.fatCopies]
		mul WORD [bootSect+s_bs.sectPerFat]
		add ebx,eax
		mov [rootStart],ebx		; first ROOT sector

		movzx eax,WORD [bootSect+s_bs.rootEntCnt]
		shl eax,5
		xor edx,edx
		div WORD [bootSect+s_bs.bytesPerSector]
		mov [sectPerRoot],eax

		add eax,ebx
		mov [dataStart],eax

		;;;;

		mov ebx,[fatStart]
		movzx ecx,WORD [bootSect+s_bs.sectPerFat]
		mov edi,fat
		call ReadSectors

		mov ebx,[rootStart]
		mov ecx,[sectPerRoot]
		mov edi,root
		call ReadSectors

		;;;;

		mov edi,files+s_file.mode
		xor al,al
		mov ecx,MAX_FILES

Init1:		mov [edi],al
		add edi,DWORD s_file.msize
		loop Init1

		mov eax,1
		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

;--------------------------------------------------------------------------------------------

ReadSectors:	and ecx,ecx
		jnz ReadSectors1
		ret

ReadSectors1:	push ebx,ecx,edi

		mov eax,[deviceID]
		mov [msgBuf+sdev_ReadSector.deviceID],eax
		mov [msgBuf+sdev_ReadSector.sectorL],ebx
		xor eax,eax
		mov [msgBuf+sdev_ReadSector.sectorH],eax

		mov ebx,[devTaskID]
		mov eax,dev_ReadSector
		mov esi,msgBuf
		mov ecx,sdev_ReadSector.msize
		mov edx,512
		int i_SendMessageW

		pop edi,ecx,ebx

		add edi,DWORD 512
		inc ebx

		loop ReadSectors1
		ret

;--------------------------------------------------------------------------------------------

Destroy:	jmp Ok

;--------------------------------------------------------------------------------------------

ReadFile:	mov esi,msgBuf+shndl_FileName.fileName
		call FindFile
		cmp eax,0xFFFFFFFF
		jz ReadFileE

		push eax,esi
		call FindFreeEntry
		and edi,edi
		jnz ReadFile0
		
		mov eax,ehndl_NoFreeEntries
		jmp Err

ReadFile0:	pop esi,eax
		mov [edi+s_file.mode],BYTE MODE_READ
		mov [edi+s_file.dir_entry],ax
		mov [edi+s_file.position],WORD 512
		mov ax,[esi+26]
		mov [edi+s_file.cluster],ax
		mov eax,[esi+28]
		mov [edi+s_file.fsize],eax

		mov eax,ebx
		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

ReadFileE:	mov eax,ehndl_FileNotFound
		jmp Err

;--------------------------------------------------------------------------------------------

GetFileSize:	mov eax,DWORD [msgBuf]
		cmp eax,MAX_FILES
		jc GetFileSize0

		xor eax,eax
		jmp Err

GetFileSize0:	mov ebx,s_file.msize
		mul ebx
		add eax,files
		mov esi,eax

		mov al,[esi+s_file.mode]
		and al,al
		jnz GetFileSize1

		xor eax,eax
		jmp Err

GetFileSize1:	movzx eax,WORD [esi+s_file.dir_entry]
		mov ebx,32
		mul ebx
		add eax,root
		mov esi,eax

		mov eax,[esi+28]
		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

;--------------------------------------------------------------------------------------------

Read:		mov eax,DWORD [msgBuf+shndl_Read.fileID]
		cmp eax,MAX_FILES
		jc Read0

		mov eax,ehndl_InvalidFileHandler
		jmp Err

Read0:		mov ebx,s_file.msize
		mul ebx
		add eax,files
		mov esi,eax

		mov al,[esi+s_file.mode]
		and al,al
		jnz Read1

		mov eax,ehndl_InvalidFileHandler
		jmp Err

Read1:		mov eax,[msgBuf+shndl_Read.blockSize]
		cmp eax,MAX_BLOCK_SIZE
		jc Read3

		mov eax,ehndl_InvalidBlockSize
		jmp Err

Read3:		mov edx,[msgBuf+shndl_Read.blockSize]
		mov edi,msgBuf
		xor ecx,ecx

Read4:		and edx,edx
		jz Read2

		mov eax,[esi+s_file.fsize]
		and eax,eax
		jnz Read5

Read2:		xor eax,eax
		mov esi,msgBuf
		int i_ProcessMessage
		jmp Start

Read5:		mov eax,512
		movzx ebx,WORD [esi+s_file.position]
		sub eax,ebx

		cmp eax,[esi+s_file.fsize]
		jc Read10
		mov eax,[esi+s_file.fsize]

Read10:		and eax,eax
		jz Read11
		jmp Read7

Read11:		movzx eax,WORD [esi+s_file.cluster]
		cmp eax,0xFF8
		jc Read6

		xor eax,eax		; bad file size (file size > clusters * clusterSize)
		jmp Err

Read6:		dec eax
		dec eax			; cluster numbers start from 2
		add eax,[dataStart]	; clusterSize == sectorSize == 512

		push edi,ecx,edx,esi

		mov [esi+s_file.data+sdev_ReadSector.sectorL],eax
		xor eax,eax
		mov [esi+s_file.data+sdev_ReadSector.sectorH],eax
		mov eax,[deviceID]
		mov [esi+s_file.data+sdev_ReadSector.deviceID],eax

		add esi,s_file.data
		mov edi,esi

		mov ebx,[devTaskID]
		mov eax,dev_ReadSector
		mov ecx,sdev_ReadSector.msize
		mov edx,512
		int i_SendMessageW

		pop esi
		push esi
		
		movzx eax,WORD [esi+s_file.cluster]
		call GetFatElement

		pop esi,edx,ecx,edi
		mov [esi+s_file.cluster],ax

		mov eax,[esi+s_file.fsize]

		cmp eax,512
		jc Read9
		mov eax,512

Read9:		mov ebx,[esi+s_file.fsize]
		sub ebx,eax
		mov [esi+s_file.fsize],ebx

		xor ebx,ebx

Read7:		cmp eax,edx		; edx - curr_blockSize
		jc Read8

		push ebx
		add ebx,edx
		mov [esi+s_file.position],bx
		pop ebx

		add ecx,edx
		xchg ecx,edx

		add esi,s_file.data
		add esi,ebx
		rep movsb

		mov ecx,edx
		xor edx,edx
		jmp Read4

Read8:		sub edx,eax
		add ecx,eax

		push ecx,esi

		mov ecx,eax
		add esi,s_file.data
		add esi,ebx
		rep movsb

		pop esi,ecx

		xor eax,eax
		mov [esi+s_file.position],ax
		jmp Read4

;--------------------------------------------------------------------------------------------

GetFatElement:	mov esi,eax
		add esi,esi
		add esi,eax
		shr esi,1
		jnc GetFatElement1

		add esi,fat
		movzx eax,WORD [esi]
		shr eax,4
		ret

GetFatElement1:	add esi,fat
		movzx eax,WORD [esi]
		and ah,0x0F
		ret

;--------------------------------------------------------------------------------------------

CloseFile:	mov eax,DWORD [msgBuf]
		cmp eax,MAX_FILES
		jc CloseFile0

		mov eax,ehndl_InvalidFileHandler
		jmp Err

CloseFile0:	mov ebx,s_file.msize
		mul ebx
		add eax,files
		mov esi,eax

		mov al,[esi+s_file.mode]
		and al,al
		jnz CloseFile1

		mov eax,ehndl_InvalidFileHandler
		jmp Err

CloseFile1:	mov [esi+s_file.mode],BYTE 0
		jmp Ok

;--------------------------------------------------------------------------------------------

FindFreeEntry:	mov edi,files
		mov ecx,MAX_FILES
		xor ebx,ebx

FindFreeEntry0:	mov al,[edi+s_file.mode]
		and al,al
		jz FindFreeEntry1

		inc ebx
		add edi,s_file.msize
		loop FindFreeEntry0

		xor edi,edi
FindFreeEntry1:	ret

;--------------------------------------------------------------------------------------------

fname:		times 8 db 0
fext:		times 3 db 0

FindFile:	mov ecx,8
		mov edi,fname

FindFile0:	mov al,[esi]
		inc esi

		and al,al
		jz FindFile1
		cmp al,'.'
		jz FindFile5
		
		mov [edi],al
		inc edi
		loop FindFile0

		mov al,[esi]
		and al,al
		jz FindFile3

FindFileE:	xor eax,eax
		dec eax
		ret

FindFile1:	mov al,' '
FindFile2:	mov [edi],al
		inc edi
		loop FindFile2

FindFile3:	mov al,' '
		mov ecx,3
FindFile4:	mov [edi],al
		inc edi
		loop FindFile4
		jmp short FindFile10

FindFile5:	mov al,' '
FindFile6:	mov [edi],al
		inc edi
		loop FindFile6

		mov ecx,3

FindFile7:	mov al,[esi]
		inc esi

		cmp al,'.'
		jz FindFileE
		and al,al
		jz FindFile8

		mov [edi],al
		inc edi
		loop FindFile7

		mov al,[esi]
		and al,al
		jnz FindFileE
		jmp short FindFile10

FindFile8:	mov al,' '
FindFile9:	mov [edi],al
		inc edi
		loop FindFile9

		;;;;

FindFile10:	mov esi,root
		xor ebx,ebx
		movzx edx,WORD [bootSect+s_bs.rootEntCnt]

FindFile11:	mov edi,fname
		mov ecx,11

		mov al,[esi]
		and al,al
		jz FindFile14

		push esi

FindFile12:	mov al,[esi]
		cmp al,[edi]
		jnz FindFile13

		inc esi
		inc edi
		loop FindFile12

		pop esi
		mov eax,ebx
		ret

FindFile13:	pop esi
		add esi,32
		inc ebx

		dec edx
		jnz FindFile11

FindFile14:	jmp FindFileE

;--------------------------------------------------------------------------------------------

devTaskID:	dd 0
deviceID:	dd 0

fatStart:	dd 0
rootStart:	dd 0
sectPerRoot:	dd 0
dataStart:	dd 0

%include "incl/debug.inc"

;------------------------------------------------------------------------------------
;;;; DATA
;------------------------------------------------------------------------------------
_DATA_START	equ $

msgBuf		equ _DATA_START
msgBuf_len	equ MAX_BLOCK_SIZE
_end_msgBuf	equ msgBuf+msgBuf_len

bootSect	equ _end_msgBuf
_end_bootSect	equ bootSect+512

fat		equ _end_bootSect
_end_fat	equ fat+(9*512)

root		equ _end_fat
_end_root	equ root+(14*512)

files		equ _end_root
_end_files	equ files + (s_file.msize * MAX_FILES)

_DATA_LEN	equ _end_files-_DATA_START
