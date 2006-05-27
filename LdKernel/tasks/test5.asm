%include "incl/macro.inc"
%include "incl/osz.inc"

		db "OSZEXE.0"		; Executable file revision 0 id
		dd 0x1000		; Stack size
		dd 0			; Data size

[ORG -0x10]
[BITS 32]

		mov ecx,5

creat:		push ecx
		xor ebx,ebx
		mov eax,msg_CreateTask
		mov esi,msg_task
		mov ecx,task_size
		xor edx,edx
		int i_SendMessageW

		mov al,[msg_task_n]
		inc al
		mov [msg_task_n],al

		pop ecx
		loop creat

		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_Exit
		int i_SendMessageW

%include "incl/console_library.inc"
%include "incl/debug.inc"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

msg_task	db "tt_"
msg_task_n	db "A"
		db 0
		times (MAX_TASK_NAME+1)-($-msg_task) db 0

		incbin "bin/test1_t.bin"
task_size	equ $-msg_task
