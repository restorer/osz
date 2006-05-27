		struc s_task
.taskID:	resd 1		; 0 - нету нифига
.state:		resb 1
.newTick:	resd 1		; need for state=STATE_SLEEP

.queue:		resd (MAX_TASKS+1)
.qFirst:  	resd 1
.qLast:		resd 1

.s_taskID:	resd 1
.s_message:	resd 1
.s_dataPtr:	resd 1
.s_dataSize:	resd 1

.taskPageAddr:	resd 1
.taskPages:	resd 1

.r_eflags:	resd 1
.r_eax:		resd 1
.r_ebx:		resd 1
.r_ecx:		resd 1
.r_edx:		resd 1
.r_esi:		resd 1
.r_edi:		resd 1
.r_ebp:		resd 1
.r_esp:		resd 1
.r_eip:		resd 1

.taskName:	resb (MAX_TASK_NAME+1)

.msize:
		endstruc

;--------------------------------------------------------------------------------------
;;;; Some variables

kernel_esp	dd 0
tasksCount	dd 0
currentID	dd 1
currentTaskN	dd 0	; номер в списке
currentTaskP	dd 0	; указатель на s_task текущей задачи

;--------------------------------------------------------------------------------------
;;;; OUT: tasks table modifed
;;;; MODIFY: EAX, ECX, EBP

InitTasks:	mov ecx,MAX_TASKS
		mov ebp,tasks
		xor eax,eax

InitTasks0:	mov [ebp+s_task.taskID], eax
		add ebp,s_task.msize
		loop InitTasks0
		ret

;--------------------------------------------------------------------------------------
;;;; IN: EAX = taskBegin, EBX = taskSize, ECX = stackSize, EDX = dataSize, ESI = taskNamePtr
;;;; OUT: if (FLAG_C) error(); else {EAX = taskID;}
;;;; MODIFY: EAX, EBX, ECX, EDX, ESI, EDI, EBP

CreateTask:
		mov [taskNamePtr],esi
		mov [taskBegin],eax
		mov [copySize],ebx
		add ebx,ecx
		add ebx,edx
		mov [taskSize],ebx

		mov ebx,[tasksCount]
		cmp ebx,MAX_TASKS
		jc CreateTask0

		stc
		ret

CreateTask0:	mov esi,tasksList
		add esi,ebx

		mov ebp,tasks
		xor cl,cl
		xor edx,edx

CreateTask1:	cmp [ebp+s_task.taskID],edx
		jz CreateTask2

		add ebp,s_task.msize
		inc cl
		jmp short CreateTask1	; свободна€ €чейка должна быть (т.к. tasksCount < MAX_TASKS). если же что-то взглюкнуло, то тут ему и придЄт зависон

CreateTask2:	mov [ebp+s_task.r_eip],edx
		mov [ebp+s_task.r_eax],edx
		mov [ebp+s_task.r_ebx],edx
		mov [ebp+s_task.r_ecx],edx
		mov [ebp+s_task.r_edx],edx
		mov [ebp+s_task.r_esi],edx
		mov [ebp+s_task.r_edi],edx
		mov [ebp+s_task.r_ebp],edx
		mov [ebp+s_task.state],BYTE STATE_RUNNING

		push esi
		push ecx
		mov eax,[taskSize]
		call SizeToPages
		mov [ebp+s_task.taskPages],ecx
		push ebp
		call AllocPages
		pop ebp
		pop ecx
		pop esi
		jnc CreateTask3

		stc
		ret

CreateTask3:	mov [esi],cl
		inc DWORD [tasksCount]

		lea esi,[ebp+s_task.queue]
		mov [ebp+s_task.qFirst],esi
		mov [ebp+s_task.qLast],esi

		mov [ebp+s_task.taskPageAddr],eax

		mov eax,[ebp+s_task.taskPages]
		imul eax,0x1000
		dec eax
		mov [ebp+s_task.r_esp],eax

		xor eax,eax	; clear ZF
		clc		; clear CF
		sti		; dirty hack, do it normally with some OR || AND at (*) place
		pushfd
		cli		; dirty hack, do it normally with some OR || AND at (*) place
		pop eax
		; (*)
		mov [ebp+s_task.r_eflags],eax

		mov esi,[taskBegin]
		mov edi,[ebp+s_task.taskPageAddr]
		mov ecx,[copySize]
		rep movsb

		lea edi,[ebp+s_task.taskName]
		mov esi,[taskNamePtr]
		mov ecx,MAX_TASK_NAME

CreateTask4:	lodsb
		and al,al
		jz CreateTask5
		stosb
		loop CreateTask4
		xor al,al
CreateTask5:	stosb

		mov eax,[currentID]
		mov [ebp+s_task.taskID],eax
		inc eax
	; тут надо бы проверить что EAX!=0 и такого PID уже нету, но это всЄ потом ^_^
		mov [currentID],eax

		clc
		ret

taskBegin	dd 0x12345678
taskSize	dd 0x12345678
copySize	dd 0x12345678
taskNamePtr	dd 0x12345678

;--------------------------------------------------------------------------------------
; IN: ESI = taskToFindNamePtr
; OUT: if (FLAG_C) error(); else {EAX = taskID; EBP = taskP;}
; MODIFY: EAX (логично), EBP (тоже логочно), ECX, EDI

FindTaskByName:
		mov ecx,[tasksCount]
		jecxz FindTaskByName3

		mov edi,tasksList
FindTaskByName0:
		movzx ebp,BYTE [edi]
		imul ebp,s_task.msize
		add ebp,tasks

		push edi
		push esi

		lea edi,[ebp+s_task.taskName]
FindTaskByName1:
		mov al,[esi]
		or al,[edi]
		jz FindTaskByName4	; success

		mov al,[esi]
		and al,al
		jz FindTaskByName2

		cmp al,[edi]
		jnz FindTaskByName2

		mov al,[edi]
		and al,al
		jz FindTaskByName2

		inc esi
		inc edi
		jmp short FindTaskByName1

FindTaskByName2:
		pop esi
		pop edi

		inc edi
		loop FindTaskByName0

FindTaskByName3:
		stc
		ret

FindTaskByName4:

		pop esi
		pop edi

		mov eax,[ebp+s_task.taskID]
		clc
		ret

;--------------------------------------------------------------------------------------
;;;; IN: EAX = taskID
;;;; OUT: if (FLAG_C) error(); else {EAX = taskN; EBP = taskP;}
;;;; MODIFY: EAX (логично), ECX, ESI, EBP (тоже логично)

FindTask:	mov ecx,[tasksCount]
		jecxz FindTask1

		mov esi,tasksList
FindTask0:	movzx ebp,BYTE [esi]
		imul ebp,s_task.msize
		add ebp,tasks

		cmp eax,[ebp+s_task.taskID]
		jz FindTask2

		inc esi
		loop FindTask0

FindTask1:	stc
		ret

FindTask2:	mov eax,esi
		sub eax,tasksList
		clc
		ret

;--------------------------------------------------------------------------------------
;;;; IN: EAX = taskID
;;;; OUT: if (FLAG_C) error(); else success();
;;;; MODIFY: EAX, ECX, ESI, EDI, {FindTask :: EBP}

KillTask:	call FindTask
		jnc KillTask0
		ret

KillTask0:	mov ecx,[tasksCount]
		dec ecx
		sub ecx,eax
		jecxz KillTask1

		mov edi,tasksList
		add edi,eax
		mov esi,edi
		inc esi

		rep movsb

KillTask1:	dec DWORD [tasksCount]
		mov [ebp+s_task.taskID],DWORD 0

		mov eax,[ebp+s_task.taskPageAddr]
		mov ecx,[ebp+s_task.taskPages]
		call FreePages

	; а тут не мешало бы "подвинуть" задачи, типа "дефрагментировать" пам€ть ^_^

		clc
		ret

;--------------------------------------------------------------------------------------

tx_NoMoreTasks	db "No more tasks",0

Schedule:	mov eax,[tasksCount]
		and eax,eax
		jnz Schedule0

		mov esi,tx_NoMoreTasks
		jmp GpFault

Schedule0:	mov eax,[currentTaskN]
		inc eax
		cmp eax,[tasksCount]
		jc Schedule1

		xor eax,eax

Schedule1:	mov [currentTaskN],eax
		add eax,tasksList
		movzx eax,BYTE [eax]
		imul eax,s_task.msize
		add eax,tasks
		mov [currentTaskP],eax
		mov ebp,eax

		mov eax,[ebp+s_task.state]
		cmp eax,STATE_SENDW
		jz Schedule0
		cmp eax,STATE_STOP
		jz Schedule0

ScheduleCurr:	cli
		mov eax,0x20
		mov [taskRunningTime],eax

		mov eax,[ebp+s_task.taskPageAddr]
		mov [task_code+2],ax	; base 00..15
		mov [task_data+2],ax
		shr eax,0x10
		mov [task_code+4],al	; base 16..23
		mov [task_code+7],ah	; base 24..31
		mov [task_data+4],al	; base 16..23
		mov [task_data+7],ah	; base 24..31

		; этааа... надо еще потом вспомнить что страничек в задаче может быть > 65535
		mov eax,[ebp+s_task.taskPages]
		mov [task_code],ax	; limit 00..15
		mov [task_data],ax	; limit 00..15

		mov [kernel_esp],esp

		mov esp,[ebp+s_task.r_esp]
		mov ax,task_data-_GDT
		mov ss,ax

		push DWORD [ds:ebp+s_task.r_eflags]
		push DWORD (task_code-_GDT)
		push DWORD [ds:ebp+s_task.r_eip]

		mov eax,[ds:ebp+s_task.r_ebp]
		push eax
		mov eax,[ds:ebp+s_task.r_eax]
		push eax

		mov ebx,[ds:ebp+s_task.r_ebx]
		mov ecx,[ds:ebp+s_task.r_ecx]
		mov edx,[ds:ebp+s_task.r_edx]
		mov esi,[ds:ebp+s_task.r_esi]
		mov edi,[ds:ebp+s_task.r_edi]

		mov ax,task_data-_GDT
		mov ds,ax
		mov es,ax

		pop eax
		pop ebp
		iretd	; fly to task ^_^
