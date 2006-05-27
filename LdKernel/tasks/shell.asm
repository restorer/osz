%include "incl/osz.inc"
%include "incl/floppy_device.inc"
%include "incl/console_library.inc"
%include "incl/keyboard_handler.inc"
%include "incl/exec_library.inc"
%include "keytabs/keycodes.inc"
%include "incl/macro.inc"

%define MAX_CMDLINE	0x100
%define MAX_PARAMS	(MAX_CMDLINE/2)

		db "OSZEXE.0"		; Executable file revision 0 id
		dd 0x1000		; Stack size
		dd _DATA_LEN		; Data size

[ORG -0x10]
[BITS 32]

		mov [prnum],BYTE 0

		mov esi,console_name
		mov ecx,console_len
		call Find
		mov [consoleID],eax

		mov esi,keyboard_name
		mov ecx,keyboard_len
		call Find
		mov [keyboardID],eax

		mov esi,exec_name
		mov ecx,exec_len
		call Find
		mov [execID],eax

	;;;;;;;;;;;;;;;;

		mov al,14
		call SetColor

		mov ebx,[consoleID]
		mov eax,cons_PrintString
		mov esi,logo
		mov ecx,logo_len
		xor edx,edx
		int i_SendMessageW

	;;;;;;;;;;;;;;;;

		mov al,10
		call SetColor

		mov ebx,[consoleID]
		mov eax,cons_PrintString
		mov esi,zversion
		mov ecx,zversion_len
		xor edx,edx
		int i_SendMessageW

	;;;;;;;;;;;;;;;;

MainLoop:	mov al,15
		call SetColor

		mov ebx,[consoleID]
		mov eax,cons_PrintString
		mov esi,prompt
		mov ecx,prompt_len
		xor edx,edx
		int i_SendMessageW

	;;;;;;;;;;;;;;;;

		mov al,7
		call SetColor
		mov edi,cmdLine

EntCmd:		call Sleep

		mov ebx,[keyboardID]
		mov eax,kbd_GetASCII
		xor ecx,ecx
		xor edx,edx
		int i_SendMessageW

		cmp ax,K_BS
		jnz EntCmd0

		cmp edi,cmdLine
		jz EntCmd
		dec edi
		jmp EntCmd2

EntCmd0:	cmp ax,K_ENT
		jnz EntCmd1
		jmp ExecuteCommand

EntCmd1:	cmp ax,' '
		jc EntCmd
		cmp ax,128
		jnc EntCmd

		cmp edi,cmdLine+MAX_CMDLINE
		jnc EntCmd

		stosb

EntCmd2:	mov [msg],al
		mov ebx,[consoleID]
		mov eax,cons_PrintChar
		mov esi,msg
		mov ecx,1
		xor edx,edx
		int i_SendMessageW
		jmp EntCmd

;--------------------------------------------------------------------------------------------

ExecuteCommand:	call NewLine
		mov [edi],BYTE 0
		call Parse

		mov esi,command
		mov edi,TX_ps
		call strcmp
		jnz ExecuteCommand0
		jmp CMD_ps

ExecuteCommand0:
		mov esi,command
		mov edi,TX_kill
		call strcmp
		jnz ExecuteCommand1
		jmp CMD_kill

ExecuteCommand1:
		mov esi,command
		mov edi,TX_rmback
		call strcmp
		jnz ExecuteCommand2
		jmp CMD_rmback

ExecuteCommand2:
		mov esi,command
		mov edi,TX_backimg
		call strcmp
		jnz ExecuteCommand3
		jmp CMD_backimg

ExecuteCommand3:
		mov esi,command
		mov edi,TX_time
		call strcmp
		jnz ExecuteCommand4
		jmp CMD_time

ExecuteCommand4:
		jmp CMD_TryToRun

;--------------------------------------------------------------------------------------------

NewLine:	mov ah,[msg]
		push ax
		mov [msg],BYTE 0x0D
		mov ebx,[consoleID]
		mov eax,cons_PrintChar
		mov esi,msg
		mov ecx,1
		xor edx,edx
		int i_SendMessageW
		pop ax
		mov [msg],ah
		ret

SetColor:	mov ah,[msg]
		push ax
		mov [msg],al
		mov ebx,[consoleID]
		mov eax,cons_SetTextColor
		mov esi,msg
		mov ecx,1
		xor edx,edx
		int i_SendMessageW
		pop ax
		mov [msg],ah
		ret

PrintTAB:	mov ah,[msg]
		push ax
		mov [msg],BYTE 9
		mov ebx,[consoleID]
		mov eax,cons_PrintChar
		mov esi,msg
		mov ecx,1
		xor edx,edx
		int i_SendMessageW
		pop ax
		mov [msg],ah
		ret

Error:		mov al,4+8
		call SetColor
		mov ebx,[consoleID]
		mov eax,cons_PrintString
		mov esi,error
		mov ecx,error_len
		xor edx,edx
		int i_SendMessageW
		ret

;--------------------------------------------------------------------------------------------

Parse:		mov esi,cmdLine
		mov edi,command
		mov [paramsCount],BYTE 0

		call Parse_spc
		and al,al
		jnz Parse0

		mov [edi],BYTE 0
Parse2:		ret

Parse0:		call Parse_cpToken
		mov edi,params

Parse1:		call Parse_spc
		and al,al
		jz Parse2

		push edi
		call Parse_cpToken
		pop edi

		add edi,MAX_CMDLINE+1
		inc BYTE [paramsCount]
		jmp Parse1

Parse_spc:	lodsb
		and al,al
		jz Parse_spc1
Parse_spc0:	cmp al," "
		jz Parse_spc
Parse_spc1:	dec esi
		ret

Parse_cpToken:	lodsb
		and al,al
		jz Parse_cpToken1
		cmp al," "
		jz Parse_cpToken0
		stosb
		jmp Parse_cpToken
Parse_cpToken0:	xor al,al
Parse_cpToken1:	stosb
		dec esi
		ret

;;;;

strcmp:		xor al,al
strcmp0:	cmp [esi],al
 		jz strcmp1
		cmp [edi],al
		jz strcmp1
		cmpsb
		jz strcmp0
		ret
strcmp1:	mov al,[esi]
		or al,[edi]
		ret

;;;;

strcpy:		mov al,[esi]
		inc esi
		mov[edi],al
		inc edi
		and al,al
		jnz strcpy
		ret

;--------------------------------------------------------------------------------------------

CMD_TryToRun:	mov esi,command
		mov edi,msg+sexec_RunProgramm.taskName
		call strcpy

		mov esi,command
		mov edi,msg+sexec_RunProgramm.fileName
		call strcpy

		mov ebx,[execID]
		mov eax,exec_RunProgramm
		mov esi,msg
		mov ecx,sexec_RunProgramm.msize-1
		xor edx,edx
		int i_SendMessageW

		jmp MainLoop

;--------------------------------------------------------------------------------------------

CMD_backimg:	mov edi,imgData
		mov eax,0x000000
		call SetCl
		mov eax,0x000080
		call SetCl
		mov eax,0x008000
		call SetCl
		mov eax,0x008080
		call SetCl
		mov eax,0x800000
		call SetCl
		mov eax,0x800080
		call SetCl
		mov eax,0x808000
		call SetCl
		mov eax,0x808080
		call SetCl
		mov eax,0x404040
		call SetCl
		mov eax,0x0000FF
		call SetCl
		mov eax,0x00FF00
		call SetCl
		mov eax,0x00FFFF
		call SetCl
		mov eax,0xFF0000
		call SetCl		
		mov eax,0xFF00FF
		call SetCl		
		mov eax,0xFFFF00
		call SetCl		
		mov eax,0xFFFFFF
		call SetCl		

		mov ecx,128-16
CMD_backimg0:	xor eax,eax
		call SetCl
		loop CMD_backimg0

		mov ecx,128
		xor dl,dl
CMD_backimg1:	mov al,dl
		shr al,1
		mov ah,al
		shl eax,8
		mov al,ah
		inc dl
		call SetCl
		loop CMD_backimg1

		mov bl,200
CMD_backimg2:	mov ecx,320
CMD_backimg3:	mov al,cl
		xor al,bl
		and al,127
		add al,128
		stosb
		loop CMD_backimg3
		dec bl
		jnz CMD_backimg2

		mov ebx,[consoleID]
		mov eax,cons_SetBackImg
		mov esi,imgData
		mov ecx,0xFC00
		xor edx,edx
		int i_SendMessageW
		jmp MainLoop

SetCl:		mov ebx,eax
		shr eax,0x10
		stosb
		mov al,bh
		stosb
		mov al,bl
		stosb
		ret

;--------------------------------------------------------------------------------------------

CMD_rmback:	mov ebx,[consoleID]
		mov eax,cons_RmBackImg
		xor ecx,ecx
		xor edx,edx
		int i_SendMessageW
		jmp MainLoop

;--------------------------------------------------------------------------------------------

CMD_time:	mov al,14
		call SetColor

		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_GetTickCount
		int i_SendMessageW

		mov [prnum+1],eax

		mov esi,prnum
		mov ecx,5
		mov ebx,[consoleID]
		xor edx,edx
		mov eax,cons_PrintNumber
		int i_SendMessageW

		call NewLine
		jmp MainLoop

;--------------------------------------------------------------------------------------------

CMD_ps:		
		xor ebx,ebx
		xor ecx,ecx
		mov edi,msg
		mov edx,msg_len
		mov eax,msg_EnumTasksID
		int i_SendMessageW
		jnc CMD_ps0

		call Error
		jmp MainLoop

CMD_ps0:	shr ecx,2
		jecxz CMD_ps1l
		jmp CMD_ps1h
CMD_ps1l:	jmp CMD_ps1

CMD_ps1h:	push ecx
		mov esi,msg
		mov edi,tasksID
		rep movsd
		pop ecx

		mov esi,tasksID

CMD_ps2:	push ecx,esi
		xor ebx,ebx
		mov ecx,4
		mov edi,msg
		mov edx,msg_len
		mov eax,msg_GetTaskName
		int i_SendMessageW
		jc CMD_ps3

		mov [edi+ecx],BYTE 0

		push esi
		mov al,10
		call SetColor
		pop esi

		lodsd
		mov [prnum+1],eax

		mov esi,prnum
		mov ecx,5
		mov ebx,[consoleID]
		xor edx,edx
		mov eax,cons_PrintNumber
		int i_SendMessageW

		call PrintTAB

		mov al,9
		call SetColor

		mov esi,msg
		mov ecx,msg_len
		mov ebx,[consoleID]
		xor edx,edx
		mov eax,cons_PrintString
		int i_SendMessageW

		call NewLine

CMD_ps3:	pop esi,ecx
		add esi,4
		loop CMD_ps2

CMD_ps1:	jmp MainLoop

;--------------------------------------------------------------------------------------------

CMD_kill:	cmp BYTE [paramsCount],1
		jnz CMD_kill1

		mov esi,params
		call ScanfHex
		jc CMD_kill1

		mov [msg],eax
		xor ebx,ebx
		mov esi,msg
		mov ecx,4
		xor edx,edx
		mov eax,msg_KillTask
		int i_SendMessageW
		jnc CMD_kill2
CMD_kill1:	call Error
CMD_kill2:	jmp MainLoop

;--------------------------------------------------------------------------------------------
;;;; IN: ESI = textPtr
;;;; OUT: if (FLAG_C) error(); else EAX = num;

ScanfHex:	xor ebx,ebx
ScanfHex0:	lodsb
		and al,al
		jnz ScanfHex1

		clc
		mov eax,ebx
		ret

ScanfHex1:	cmp al,'0'
		jc ScanfHex5
		cmp al,'9'+1
		jnc ScanfHex2

		sub al,'0'
		jmp short ScanfHex4

ScanfHex2:	cmp al,'A'
		jc ScanfHex5
		cmp al,'F'+1
		jnc ScanfHex3

		sub al,'A'-10
		jmp short ScanfHex4

ScanfHex3:	cmp al,'a'
		jc ScanfHex5
		cmp al,'f'+1
		jnc ScanfHex5

		sub al,'a'-10

ScanfHex4:	shl ebx,4
		or bl,al
		jmp short ScanfHex0

ScanfHex5:	xor eax,eax
		stc
		ret

;--------------------------------------------------------------------------------------------

TX_ps		db "ps",0
TX_kill		db "kill",0
TX_rmback	db "rmback",0
TX_backimg	db "backimg",0
TX_time		db "time",0
TX_test		db "test",0

error		db "Error",0x0D
error_len	equ $-error

logo		db "    ,&m,       ,",0x0D
		db "   ,$#&$m,.,m&$f    [Restorer/FSB'o5]",0x0D
		db "   &$&#&$$$$$$;",0x0D
		db "   $&#&$$$$$$&k             _     __  __",0x0D
		db "    &&#&$&$$$$$,           (_) __)     /__",0x0D
		db "     `&T&$&$&$$$,                      ",0x0D
		db "        `{&T$$$$$b,",0x0D
		db '           ~"{&T$$$b.',0x0D
		db '                ~~"{$;.',0x0D
		db 0x0D
logo_len	equ $-logo

zversion	db "OsZ-i86 version 0.04 (23.05.2006)",0x0D
		db 0x0D
zversion_len	equ $-zversion

prompt		db "[prozrok@localmachine /]# "
prompt_len	equ $-prompt

;--------------------------------------------------------------------------------------------

execID		dd 0
exec_name	db "exec.library"
exec_len	equ $-exec_name

consoleID	dd 0
console_name	db "console.library"
console_len	equ $-console_name

keyboardID	dd 0
keyboard_name	db "keyboard.handler"
keyboard_len	equ $-keyboard_name

testx		dw 0x4321
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

%include "incl/debug.inc"

;--------------------------------------------------------------------------------------------
;;;; DATA
;--------------------------------------------------------------------------------------------
_DATA_START	equ $

msg		equ _DATA_START
_end_msg	equ msg+0x100
msg_len		equ _end_msg-msg

cmdLine		equ _end_msg
_end_cmdLine	equ cmdLine+MAX_CMDLINE+1

command		equ _end_cmdLine
_end_command	equ command+MAX_CMDLINE+1
params		equ _end_command
_end_params	equ params+(MAX_PARAMS*(MAX_CMDLINE+1))
paramsCount	equ _end_params
_end_paramsCount	equ paramsCount+1

tasksID		equ _end_paramsCount
_end_tasksID	equ tasksID+0x100

prnum		equ _end_tasksID
_end_prnum	equ prnum+5

imgData		equ _end_prnum
_end_imgData	equ imgData+0xFC00

_DATA_LEN	equ _end_imgData-_DATA_START
