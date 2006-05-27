%include "incl/defines.asm"
%include "incl/osz.inc"
%include "incl/16bit.asm"
%include "incl/32bit.asm"

;-----------------------------------------------------------------------------------
;;;; So, Here W Go

		mov al,1
		call SetVideoMode

		call InitTasks

		mov eax,Ts1+0x10	; Task begin
		mov ebx,Ts2-Ts1-0x10	; Task size
		mov ecx,[Ts1+8]		; Stack size
		mov edx,[Ts1+12]	; Data size
		mov esi,ts1Name		; Task name
		call CreateTask

		mov eax,Ts2+0x10	; Task begin
		mov ebx,Ts3-Ts2-0x10	; Task size
		mov ecx,[Ts2+8]		; Stack size
		mov edx,[Ts2+12]	; Data size
		mov esi,ts2Name		; Task name
		call CreateTask

		mov eax,Ts3+0x10	; Task begin
		mov ebx,Ts4-Ts3-0x10	; Task size
		mov ecx,[Ts3+8]		; Stack size
		mov edx,[Ts3+12]	; Data size
		mov esi,ts3Name		; Task name
		call CreateTask

		mov eax,Ts4+0x10	; Task begin
		mov ebx,Ts5-Ts4-0x10	; Task size
		mov ecx,[Ts4+8]		; Stack size
		mov edx,[Ts4+12]	; Data size
		mov esi,ts4Name		; Task name
		call CreateTask

		mov eax,Ts5+0x10	; Task begin
		mov ebx,Ts6-Ts5-0x10	; Task size
		mov ecx,[Ts5+8]		; Stack size
		mov edx,[Ts5+12]	; Data size
		mov esi,ts5Name		; Task name
		call CreateTask

		mov eax,Ts6+0x10	; Task begin
		mov ebx,Ts7-Ts6-0x10	; Task size
		mov ecx,[Ts6+8]		; Stack size
		mov edx,[Ts6+12]	; Data size
		mov esi,ts6Name		; Task name
		call CreateTask

		jmp Schedule

Ts1:		incbin "tasks/bin/exec_library.bin"
Ts2:		incbin "tasks/bin/floppy_device.bin"
Ts3:		incbin "tasks/bin/fat12_handler.bin"
Ts4:		incbin "tasks/bin/init.bin"
Ts5:		incbin "tasks/bin/console_library.bin"
Ts6:		incbin "tasks/bin/keyboard_handler.bin"
Ts7:

ts1Name		db "exec.library",0
ts2Name		db "floppy.device",0
ts3Name		db "fat12.handler",0
ts4Name		db "init",0
ts5Name		db "console.library",0
ts6Name		db "keyboard.handler",0

;-------------------------------------------------------------------------------

%include "incl/globals.asm"
%include "incl/video.asm"
%include "incl/mm.asm"
%include "incl/tasks.asm"

%include "incl/rmode.asm"
%include "incl/irqs.asm"
%include "incl/kprinting.asm"
%include "incl/gpfault.asm"
%include "incl/except_fault.asm"
%include "incl/irq_handlers.asm"
%include "incl/messages.asm"

%include "incl/tables.asm"
