%include "incl/macro.inc"
%include "incl/osz.inc"
%include "incl/fat12_handler.inc"

		dd 0x1000		; Stack size
		dd _DATA_LEN		; Data size

[ORG -8]
[BITS 32]

		mov esi,fat12_name
		mov ecx,fat12_len
		call Find
		mov [fat12_ID],eax

		mov eax,1

lp0:		push eax
		mov ecx,1

lp1:		push ecx

		mov [__dbg_msg+1],eax
		call __dbg_PrintNumS

		mov [__dbg_msg+1],ecx
		call __dbg_PrintNumS

		push eax,ecx

		mov esi,strx
		mov ecx,strx_len
		call __dbg_PrintStrS

		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_GetTickCount
		int i_SendMessageW
		mov [tmex],eax

		pop ecx,eax

		;;;;

		mov [msg+shndl_Read.blockSize],eax
		xchg eax,ecx

		shl eax,11
		xor edx,edx
		div ecx

		mov ecx,eax
		push ecx

		mov ebx,[fat12_ID]
		mov eax,hndl_ReadFile
		mov esi,msg_of
		mov ecx,msg_of_len
		xor edx,edx
		int i_SendMessageW

		pop ecx

		cmp eax,0xFFFF0000
		jc lp2
		jmp lpe

lp2:		mov [msg+shndl_Read.fileID],eax
lp3:		push ecx

		mov ebx,[fat12_ID]
		mov eax,hndl_Read
		mov esi,msg
		mov ecx,shndl_Read.msize
		mov edi,buf
		mov edx,buf_len
		int i_SendMessageW

		pop ecx
		loop lp3

		;;;;

lpe:		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_GetTickCount
		int i_SendMessageW

		sub eax,DWORD [tmex]
		mov [__dbg_msg+1],DWORD eax
		call __dbg_PrintNum

		pop ecx
		add ecx,ecx

		pop eax
		push eax

		cmp ecx,32+1
		jc lp1

		pop eax
		add eax,eax
		cmp eax,512+1
		jc lp0

		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_Exit
		int i_SendMessageW


tmex		dd 0

;;;;

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

;;;;

msg		dd 0
		dd 0

msg_of		dd 0
		db "LDKERNEL",0
msg_of_len	equ $-msg_of

fat12_ID	dd 0
fat12_name	db "fat12.handler"
fat12_len	equ $-fat12_name

strx		db "="
strx_len	equ $-strx

;--------------------------------------------------------------------------------------------
;;;; DATA
;--------------------------------------------------------------------------------------------
_DATA_START	equ $

buf		equ _DATA_START
buf_len		equ 1024
_end_buf	equ buf+buf_len

_DATA_LEN	equ _end_buf-_DATA_START
