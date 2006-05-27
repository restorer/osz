%include "incl/macro.inc"
%include "incl/osz.inc"
%include "incl/exec_library.inc"

		db "OSZEXE.0"		; Executable file revision 0 id
		dd 0x1000		; Stack size
		dd _DATA_LEN		; Data size

[ORG -0x10]
[BITS 32]

		mov esi,exec_name
		mov ecx,exec_len
		call Find
		mov [execID],eax

		;;;;

		mov ebx,[execID]
		mov eax,exec_RunProgramm
		mov esi,prog1
		mov ecx,prog1_len
		xor edx,edx
		int i_SendMessageW

		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_Exit
		int i_SendMessageW

		;;;;

prog1		db "shell",0
		times (MAX_TASK_NAME+1)-($-prog1) db 0
		db "SHELL",0
prog1_len	equ $-prog1

;-------------------------------------------------------------------------

execID		dd 0
exec_name	db "exec.library"
exec_len	equ $-exec_name

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

msg		equ _DATA_START
msg_len		equ 32768
_end_msg	equ msg+msg_len

_DATA_LEN	equ _end_msg-_DATA_START
