%include "incl/macro.inc"
%include "incl/osz.inc"

		dd 0x1000		; Stack size
		dd _DATA_LEN		; Data size

[ORG -8]
[BITS 32]

		mov eax,10

lp0:		push eax
		mov ecx,10

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

lp2:		push eax

		push ecx
		mov esi,tb
lp3:		call Rand
		mov [esi],al
		inc esi
		loop lp3
		pop ecx


		pop eax
		dec eax
		jnz lp2

		;;;;

		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_GetTickCount
		int i_SendMessageW

		sub eax,DWORD [tmex]
		mov [__dbg_msg+1],DWORD eax
		call __dbg_PrintNum

		pop ecx

		mov eax,ecx
		mov ebx,10
		mul ebx
		mov ecx,eax

		pop eax
		push eax

		cmp ecx,10001
		jc lp1

		pop eax
		mov ebx,10
		mul ebx
		cmp eax,10001
		jc lp0

		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_Exit
		int i_SendMessageW


tmex		dd 0

;;;;

Rand:		mov al,[rand0]
		add al,[rand1]
		mov [rand1],al
		add al,[rand2]
		mov [rand2],al
		add al,[rand3]
		mov [rand3],al
		add al,[rand4]
		mov [rand4],al
		add al,[rand5]
		mov [rand5],al
		add al,[rand6]
		mov [rand6],al
		add al,[rand7]
		mov [rand7],al
		add al,[rand0]
		mov [rand0],al
		ret

rand0		db 0x76
rand1		db 0x23
rand2		db 0x26
rand3		db 0x73
rand4		db 0x06
rand5		db 0x12
rand6		db 0x87
rand7		db 0x34

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

strx		db "="
strx_len	equ $-strx

;--------------------------------------------------------------------------------------------
;;;; DATA
;--------------------------------------------------------------------------------------------
_DATA_START	equ $

tb		equ _DATA_START
tb_len		equ 20000
_end_tb		equ tb+tb_len

_DATA_LEN	equ _end_tb-_DATA_START
