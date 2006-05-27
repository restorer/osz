%include "incl/osz.inc"
%include "incl/keyboard_handler.inc"
%include "keytabs/keycodes.inc"

%define MAX_KBUF_LEN	32

		db "OSZEXE.0"		; Executable file revision 0 id
		dd 0x1000		; Stack size
		dd _DATA_LEN		; Data size

[ORG -0x10]
[BITS 32]

		mov [DAT+currTable],DWORD (ktab+9)

Start:		mov edi,DAT+msg
		mov edx,msgE-msg
		int i_GetMessage
		jnz Process

		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_GetScanCode
		int i_SendMessageW
		jc Start0

		call ScanToASCII
		and ax,ax
		jz Start0

		movzx ecx,BYTE [DAT+bufLen]
		cmp cl,MAX_KBUF_LEN
		jnc Start0

		mov edi,DAT+KBuf
		add edi,ecx
		add edi,ecx
		stosw

		inc cl
		mov [DAT+bufLen],cl

Start0:		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_Sleep
		int i_SendMessageW
		jmp Start

Process:	cmp eax,kbd_GetASCII
		jnz Process0
		jmp MSG_GetASCII
Process0:
		mov eax,1
		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

;-------------------------------------------------------------------------------

MSG_GetASCII:	and ecx,ecx
		jnz StdParamsErr

		movzx ecx,BYTE [DAT+bufLen]
		and cl,cl
		jnz MSG_GetASCII0
		jmp StdProcessMsg

MSG_GetASCII0:	movzx eax,WORD [DAT+KBuf]
		push eax

		dec cl
		mov [DAT+bufLen],cl
		jecxz MSG_GetASCII1

		mov edi,DAT+KBuf
		mov esi,DAT+KBuf+2
		rep movsw

MSG_GetASCII1:	pop eax
		jmp StdProcessMsgEax

;-------------------------------------------------------------------------------

StdParamsErr:	mov eax,2
		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

StdProcessMsg:	xor eax,eax
StdProcessMsgEax:
		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

;-------------------------------------------------------------------------------

ScanToASCII:	and ah,ah
		jnz ScanToASCII0

		xor cl,cl
		jmp ScanToASCII2

ScanToASCII0:	cmp ah,0xE0
		jnz ScanToASCII1

		mov cl,2
		jmp ScanToASCII2

ScanToASCII1:	mov cl,al
		and al,0x7F
		cmp ax,0xE145
		jnz ScanToASCII5

		xor ax,ax
		mov al,cl
		and al,0x80
		xor cl,cl

ScanToASCII2:	test al,0x80
		jz ScanToASCII3

		inc cl
		and al,0x7F

ScanToASCII3:	movzx ecx,cl
		movzx eax,al

		shl eax,3
		add eax,ecx
		add eax,ecx
		add eax,[DAT+currTable]
		mov ax,[eax]

		mov cl,ah
		and cl,0xF0
		cmp cl,0x70
		jz ScanToASCII4
		ret

ScanToASCII4:	mov bl,ah
		movzx eax,al
		shl eax,(3+7)
		add eax,ktab+9
		mov [DAT+currTable],eax

;		mov al,bl
;		shl al,1
;		and al,0110b
;		shr bl,2
;		and bl,0001b
;		or bl,al

;		mov al,0xED	; эта херня не работает
;		out 0x60,al
;		jmp short $+2
;		mov al,ah
;		out 0x60,al

ScanToASCII5:	xor ax,ax
		ret

;-------------------------------------------------------------------------------

ktab:
%include "keytabs/keytab1.inc"

;-------------------------------------------------------------------------------

DAT:		struc _DATA
currTable: 	resd 1
bufLen:		resb 1
KBuf:		resw MAX_KBUF_LEN
msg:		resb 0x100
msgE:
_DATA_LEN:
		endstruc
