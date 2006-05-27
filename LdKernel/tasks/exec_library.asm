%include "incl/macro.inc"
%include "incl/osz.inc"
%include "incl/floppy_device.inc"
%include "incl/fat12_handler.inc"
%include "incl/exec_library.inc"

%define R_BLOCK_SIZE 512

		db "OSZEXE.0"		; Executable file revision 0 id
		dd 0x1000		; Stack size
		dd _DATA_LEN		; Data size

[ORG -0x10]
[BITS 32]

		mov esi,floppy_name
		mov ecx,floppy_len
		call Find
		mov [floppyID],eax

		mov esi,fat12_name
		mov ecx,fat12_len
		call Find
		mov [fat12_ID],eax

		;;;;

		mov ebx,[floppyID]
		mov eax,dev_Open
		xor ecx,ecx
		xor edx,edx
		int i_SendMessageW
		mov [floppyDevID],eax

		;;;;

		mov eax,[floppyID]
		mov [msg+shndl_Init.devTaskID],eax
		mov eax,[floppyDevID]
		mov [msg+shndl_Init.deviceID],eax

		mov ebx,[fat12_ID]
		mov eax,hndl_Init
		mov esi,msg
		mov ecx,shndl_Init.msize
		xor edx,edx
		int i_SendMessageW
		mov [handlerID],eax

		;;;;

Start:		mov edi,msg_in
		mov edx,msg_in_len
		int i_GetMessage
		jnz Process

		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_Sleep
		int i_SendMessageW
		jmp Start

Process:	cmp eax,exec_RunProgramm
		jnz Process0
		jmp RunProgramm

Process0:
Ok:		xor eax,eax
Err:		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

;-------------------------------------------------------------------------

RunProgramm:	push ecx

		mov ecx,0x100
		mov esi,msg_in+sexec_RunProgramm.fileName
		mov edi,msg+shndl_FileName.fileName
		rep movsb

		mov eax,[handlerID]
		mov [msg+shndl_FileName.handlerID],eax

		mov ebx,[fat12_ID]
		mov eax,hndl_ReadFile
		mov esi,msg

		pop ecx
		add ecx,4

		xor edx,edx
		int i_SendMessageW

		cmp eax,0xFFFF0000
		jc RunProgramm2
		jmp Err

RunProgramm2:	mov [msg+shndl_Read.fileID],eax
		mov [msg+shndl_Read.blockSize],DWORD R_BLOCK_SIZE

		;;;;

		mov edi,buffer+krnl_CreateTask.stackSize-8
		xor edx,edx

RunProgramm0:	push edi,edx

		mov ebx,[fat12_ID]
		mov eax,hndl_Read
		mov esi,msg
		mov ecx,shndl_Read.msize
		mov edx,R_BLOCK_SIZE
		int i_SendMessageW

		pop edx,edi

		add edx,ecx
		cmp ecx,R_BLOCK_SIZE
		jc RunProgramm1

		add edi,R_BLOCK_SIZE
		jmp short RunProgramm0

RunProgramm1:
		mov ecx,MAX_TASK_NAME+1
		mov esi,msg_in+sexec_RunProgramm.taskName
		mov edi,buffer+krnl_CreateTask.taskName
		rep movsb

		xor ebx,ebx
		mov eax,msg_CreateTask
		mov esi,buffer
		mov ecx,edx
		add ecx,krnl_CreateTask.msize-0x10
		xor edx,edx
		int i_SendMessageW

		mov ebx,[fat12_ID]
		mov eax,hndl_CloseFile
		mov esi,msg
		mov ecx,shndl_FileHandler.msize
		xor edx,edx
		int i_SendMessageW

		jmp Ok

;-------------------------------------------------------------------------

floppyID	dd 0
floppy_name	db "floppy.device"
floppy_len	equ $-floppy_name

fat12_ID	dd 0
fat12_name	db "fat12.handler"
fat12_len	equ $-fat12_name

floppyDevID	dd 0
handlerID	dd 0

;--------------------------------------------------------------------------------------------

Find:		xor ebx,ebx
		xor edx,edx
		mov eax,msg_FindTaskByName
		int i_SendMessageW
		jnc Find0
		jmp BigError
Find0:		ret

;;;;

Sleep:		xor ebx,ebx
		mov eax,msg_Sleep
		xor ecx,ecx
		xor edx,edx
		int i_SendMessageW
		ret

;;;;

BigError:	mov ax,0xFAC0
		mov ds,ax

%include "incl/console_library.inc"
%include "incl/debug.inc"

;--------------------------------------------------------------------------------------------
;;;; DATA
;--------------------------------------------------------------------------------------------
_DATA_START	equ $

msg_in		equ _DATA_START
msg_in_len	equ 0x200
_end_msg_in	equ msg_in+msg_in_len

msg		equ _end_msg_in
msg_len		equ 0x100
_end_msg	equ msg+msg_len

buffer		equ _end_msg
buffer_len	equ 32768
_end_buffer	equ buffer+buffer_len

_DATA_LEN	equ _end_buffer-_DATA_START
