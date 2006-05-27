Int_GetMessage:
		cli
		push eax
		mov ax,kernel_data-_GDT
		mov ds,ax
		mov es,ax
		mov gs,ax
		mov fs,ax
		pop eax
		;;;;
		mov [task_ebp],ebp
		mov ebp,[currentTaskP]
		mov [ds:ebp+s_task.r_eax],eax
		mov [ds:ebp+s_task.r_ebx],ebx
		mov [ds:ebp+s_task.r_ecx],ecx
		mov [ds:ebp+s_task.r_edx],edx
		mov [ds:ebp+s_task.r_esi],esi
		mov [ds:ebp+s_task.r_edi],edi
		mov eax,[task_ebp]
		mov [ds:ebp+s_task.r_ebp],eax
		;;;;
		pop eax
		mov [ds:ebp+s_task.r_eip],eax
		;;;;
		pop eax		; task_cs
		;;;;
		pop eax
		mov [ds:ebp+s_task.r_eflags],eax
		;;;;
		mov [ds:ebp+s_task.r_esp],esp
		;;;;
		mov ax,kernel_data-_GDT
		mov ss,ax
		mov esp,[kernel_esp]

		mov esi,[ebp+s_task.qFirst]
		cmp esi,[ebp+s_task.qLast]
		jnz Int_GetMessage0

		or [ebp+s_task.r_eflags],DWORD ZF_OR
		jmp Int_ScheduleCurr_succ

Int_GetMessage0:
		lodsd

		push ebp
		;;;;
		call FindTask
		jnc Int_GetMessage1
		;;;;
		pop ebp
		mov eax,RESULT_INVALID_TASKID
		jmp Int_ScheduleCurr_errEax
		;;;;
Int_GetMessage1:
		pop edi

		mov ecx,[ebp+s_task.r_ecx]
		mov eax,[edi+s_task.r_edx]
		cmp eax,ecx
		jnc Int_GetMessage2

		mov ebp,edi
		mov eax,RESULT_BUFFER_TOO_SMALL
		jmp Int_ScheduleCurr_errEax

Int_GetMessage2:
		mov eax,[ebp+s_task.taskID]
		mov [edi+s_task.r_ebx],eax
		mov eax,[ebp+s_task.r_eax]
		mov [edi+s_task.r_eax],eax
		mov [edi+s_task.r_ecx],ecx
		and [edi+s_task.r_eflags],DWORD ZF_AND

		push edi
		;;;;
		mov eax,[edi+s_task.taskPageAddr]
		mov edi,[edi+s_task.r_edi]
		add edi,eax
		;;;;
		mov esi,[ebp+s_task.r_esi]
		add esi,[ebp+s_task.taskPageAddr]
		;;;;
		rep movsb
		;;;;
		pop ebp

		jmp Int_ScheduleCurr_succ

;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------

Int_SendMessageW:
		cli
		push eax
		mov ax,kernel_data-_GDT
		mov ds,ax
		mov es,ax
		mov gs,ax
		mov fs,ax
		pop eax
		;;;;
		mov [task_ebp],ebp
		mov ebp,[currentTaskP]
		mov [ds:ebp+s_task.r_eax],eax
		mov [ds:ebp+s_task.r_ebx],ebx
		mov [ds:ebp+s_task.r_ecx],ecx
		mov [ds:ebp+s_task.r_edx],edx
		mov [ds:ebp+s_task.r_esi],esi
		mov [ds:ebp+s_task.r_edi],edi
		mov eax,[task_ebp]
		mov [ds:ebp+s_task.r_ebp],eax
		;;;;
		pop eax
		mov [ds:ebp+s_task.r_eip],eax
		;;;;
		pop eax		; task_cs
		;;;;
		pop eax
		mov [ds:ebp+s_task.r_eflags],eax
		;;;;
		mov [ds:ebp+s_task.r_esp],esp
		;;;;
		mov ax,kernel_data-_GDT
		mov ss,ax
		mov esp,[kernel_esp]

		mov eax,[ebp+s_task.r_ebx]
		and eax,eax
		jz Int_SendMessageWkrnl
		jmp Int_SendMessageWprc

Int_SendMessageWkrnl:
		mov eax,[ebp+s_task.r_eax]

		cmp eax,msg_Sleep
		jnz Sc0
		jmp SysCall_Sleep
Sc0:		cmp eax,msg_GetTickCount
		jnz Sc1
		jmp SysCall_GetTickCount
Sc1:		cmp eax,msg_SetPixel
		jnz Sc2
		jmp SysCall_SetPixel
Sc2:		cmp eax,msg_FindTaskByName
		jnz Sc3
		jmp SysCall_FindTaskByName
Sc3:		cmp eax,msg_RmodeInt
		jnz Sc4
		jmp SysCall_RmodeInt
Sc4:		cmp eax,msg_GetScanCode
		jnz Sc5
		jmp SysCall_GetScanCode
Sc5:		cmp eax,msg_EnumTasksID
		jnz Sc6
		jmp SysCall_EnumTasksID
Sc6:		cmp eax,msg_GetTaskName
		jnz Sc7
		jmp SysCall_GetTaskName
Sc7:		cmp eax,msg_KillTask
		jnz Sc8
		jmp SysCall_KillTask
Sc8:		cmp eax,msg_Exit
		jnz Sc9
		jmp SysCall_Exit
Sc9:		cmp eax,msg_CreateTask
		jnz Sc10
		jmp SysCall_CreateTask
Sc10:
		mov eax,RESULT_INCORRECT_SYSCALL
		jmp Int_ScheduleCurr_errEax

Int_SendMessageWprc:
		mov [senderP],ebp
		call FindTask
		jnc Int_SendMessageWprc1

		mov ebp,[senderP]
		mov eax,RESULT_INVALID_TASKID
		jmp Int_ScheduleCurr_errEax

Int_SendMessageWprc1:
		push ebp
		mov ebp,[senderP]
		mov eax,[ebp+s_task.taskID]
		pop ebp

		mov esi,[ebp+s_task.qLast]
		lea edi,[ebp+(s_task.queue+(MAX_TASKS+1)*4)]
		add esi,4
		cmp esi,edi
		jc Int_SendMessageWprc2
		lea esi,[ebp+s_task.queue]

Int_SendMessageWprc2:
		cmp esi,[ebp+s_task.qFirst]
		jz Int_SendMessageWprc3

		mov edi,[ebp+s_task.qLast]
		stosd
		mov [ebp+s_task.qLast],esi

		mov ebp,[senderP]
		mov [ebp+s_task.state],BYTE STATE_SENDW
		jmp Schedule

Int_SendMessageWprc3:
		mov ebp,[senderP]
		mov eax,RESULT_TOO_MANY_MESSAGES
		jmp Int_ScheduleCurr_errEax

senderP		dd 0

;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------

Int_ProcessMessage:
		cli
		push eax
		mov ax,kernel_data-_GDT
		mov ds,ax
		mov es,ax
		mov gs,ax
		mov fs,ax
		pop eax
		;;;;
		mov [task_ebp],ebp
		mov ebp,[currentTaskP]
		mov [ds:ebp+s_task.r_eax],eax
		mov [ds:ebp+s_task.r_ebx],ebx
		mov [ds:ebp+s_task.r_ecx],ecx
		mov [ds:ebp+s_task.r_edx],edx
		mov [ds:ebp+s_task.r_esi],esi
		mov [ds:ebp+s_task.r_edi],edi
		mov eax,[task_ebp]
		mov [ds:ebp+s_task.r_ebp],eax
		;;;;
		pop eax
		mov [ds:ebp+s_task.r_eip],eax
		;;;;
		pop eax		; task_cs
		;;;;
		pop eax
		mov [ds:ebp+s_task.r_eflags],eax
		;;;;
		mov [ds:ebp+s_task.r_esp],esp
		;;;;
		mov ax,kernel_data-_GDT
		mov ss,ax
		mov esp,[kernel_esp]

		mov esi,[ebp+s_task.qFirst]
		cmp esi,[ebp+s_task.qLast]
		jnz Int_ProcessMessage0

		mov eax,RESULT_NO_MORE_MESSAGES
		jmp Int_ScheduleCurr_errEax

Int_ProcessMessage0:
		lodsd

		lea edi,[ebp+(s_task.queue+(MAX_TASKS+1)*4)]
		cmp esi,edi
		jnz Int_ProcessMessage1
		lea esi,[ebp+s_task.queue]

Int_ProcessMessage1:
		mov [ebp+s_task.qFirst],esi

		push ebp
		;;;;
		call FindTask
		jnc Int_ProcessMessage2
		;;;;
		pop ebp
		mov eax,RESULT_INVALID_TASKID
		jmp Int_ScheduleCurr_errEax
		;;;;
Int_ProcessMessage2:
		mov [ebp+s_task.state],DWORD STATE_RUNNING
		;;;;
		pop esi

		mov ecx,[esi+s_task.r_ecx]
		mov eax,[ebp+s_task.r_edx]
		cmp eax,ecx
		jnc Int_ProcessMessage3

		mov [ebp+s_task.r_eax],DWORD RESULT_BUFFER_TOO_SMALL
		or [ebp+s_task.r_eflags],DWORD CF_OR
		mov ebp,esi
		jmp Int_ScheduleCurr_succ

Int_ProcessMessage3:
		mov eax,[esi+s_task.r_eax]
		mov [ebp+s_task.r_eax],eax
		mov [ebp+s_task.r_ecx],ecx
		and [ebp+s_task.r_eflags],DWORD CF_AND

		push esi
		;;;;
		mov eax,[esi+s_task.taskPageAddr]
		mov esi,[esi+s_task.r_esi]
		add esi,eax
		;;;;
		mov edi,[ebp+s_task.r_edi]
		add edi,[ebp+s_task.taskPageAddr]
		;;;;
		rep movsb
		;;;;
		pop ebp

		jmp Int_ScheduleCurr_succ

;-------------------------------------------------------------------------------

task_ebp	dd 0

Int_ScheduleCurr_succEax:
		mov [ebp+s_task.r_eax],eax
		mov [ebp+s_task.r_ecx],DWORD 0
Int_ScheduleCurr_succ:
		and [ebp+s_task.r_eflags],DWORD CF_AND
		jmp ScheduleCurr

;;;;

Int_ScheduleCurr_errEax:
		mov [ebp+s_task.r_eax],eax
		or [ebp+s_task.r_eflags],DWORD CF_OR
		jmp ScheduleCurr

;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------

Int_RemoveMessage:
		cli
		push eax
		mov ax,kernel_data-_GDT
		mov ds,ax
		mov es,ax
		mov gs,ax
		mov fs,ax
		pop eax
		;;;;
		mov [task_ebp],ebp
		mov ebp,[currentTaskP]
		mov [ds:ebp+s_task.r_eax],eax
		mov [ds:ebp+s_task.r_ebx],ebx
		mov [ds:ebp+s_task.r_ecx],ecx
		mov [ds:ebp+s_task.r_edx],edx
		mov [ds:ebp+s_task.r_esi],esi
		mov [ds:ebp+s_task.r_edi],edi
		mov eax,[task_ebp]
		mov [ds:ebp+s_task.r_ebp],eax
		;;;;
		pop eax
		mov [ds:ebp+s_task.r_eip],eax
		;;;;
		pop eax		; task_cs
		;;;;
		pop eax
		mov [ds:ebp+s_task.r_eflags],eax
		;;;;
		mov [ds:ebp+s_task.r_esp],esp
		;;;;
		mov ax,kernel_data-_GDT
		mov ss,ax
		mov esp,[kernel_esp]

		mov esi,[ebp+s_task.qFirst]
		cmp esi,[ebp+s_task.qLast]
		jnz Int_RemoveMessage0

		mov eax,RESULT_NO_MORE_MESSAGES
		jmp Int_ScheduleCurr_errEax

Int_RemoveMessage0:
		add esi,4
		lea edi,[ebp+(s_task.queue+(MAX_TASKS+1)*4)]
		cmp esi,edi
		jnz Int_RemoveMessage1
		lea esi,[ebp+s_task.queue]

Int_RemoveMessage1:
		mov [ebp+s_task.qFirst],esi
		jmp Int_ScheduleCurr_succ

;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------

Int_SendAnswer:
		cli
		push eax
		mov ax,kernel_data-_GDT
		mov ds,ax
		mov es,ax
		mov gs,ax
		mov fs,ax
		pop eax
		;;;;
		mov [task_ebp],ebp
		mov ebp,[currentTaskP]
		mov [ds:ebp+s_task.r_eax],eax
		mov [ds:ebp+s_task.r_ebx],ebx
		mov [ds:ebp+s_task.r_ecx],ecx
		mov [ds:ebp+s_task.r_edx],edx
		mov [ds:ebp+s_task.r_esi],esi
		mov [ds:ebp+s_task.r_edi],edi
		mov eax,[task_ebp]
		mov [ds:ebp+s_task.r_ebp],eax
		;;;;
		pop eax
		mov [ds:ebp+s_task.r_eip],eax
		;;;;
		pop eax		; task_cs
		;;;;
		pop eax
		mov [ds:ebp+s_task.r_eflags],eax
		;;;;
		mov [ds:ebp+s_task.r_esp],esp
		;;;;
		mov ax,kernel_data-_GDT
		mov ss,ax
		mov esp,[kernel_esp]

		mov eax,[ebp+s_task.r_ebx]

		push ebp
		;;;;
		call FindTask
		jnc Int_SendAnswer0
		;;;;
		pop ebp
		mov eax,RESULT_INVALID_TASKID
		jmp Int_ScheduleCurr_errEax
		;;;;
Int_SendAnswer0:
		mov [ebp+s_task.state],DWORD STATE_RUNNING
		;;;;
		pop esi

		mov ecx,[esi+s_task.r_ecx]
		mov eax,[ebp+s_task.r_edx]
		cmp eax,ecx
		jnc Int_SendAnswer1

		mov [ebp+s_task.r_eax],DWORD RESULT_BUFFER_TOO_SMALL
		or [ebp+s_task.r_eflags],DWORD CF_OR
		mov ebp,esi
		jmp Int_ScheduleCurr_succ

Int_SendAnswer1:
		mov eax,[esi+s_task.r_eax]
		mov [ebp+s_task.r_eax],eax
		mov [ebp+s_task.r_ecx],ecx
		and [ebp+s_task.r_eflags],DWORD CF_AND

		push esi
		;;;;
		mov eax,[esi+s_task.taskPageAddr]
		mov esi,[esi+s_task.r_esi]
		add esi,eax
		;;;;
		mov edi,[ebp+s_task.r_edi]
		add edi,[ebp+s_task.taskPageAddr]
		;;;;
		rep movsb
		;;;;
		pop ebp

		jmp Int_ScheduleCurr_succ

;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------

SysCall_Sleep:	xor eax,eax
		mov [ebp+s_task.r_eax],eax
		mov [ebp+s_task.r_ecx],eax
		and [ebp+s_task.r_eflags],DWORD CF_AND
		jmp Schedule

;-----------------------------------------------------------------------------------------------

SysCall_GetTickCount:
		mov eax,[globalTime]
		jmp Int_ScheduleCurr_succEax

;-----------------------------------------------------------------------------------------------

SysCall_SetPixel:
		mov ecx,[ebp+s_task.r_ecx]
		cmp ecx,5
		jz Sc_SetPixel0

		mov eax,RESULT_INCORRECT_SYSCALL_PARAMS
		jmp Int_ScheduleCurr_errEax

Sc_SetPixel0:
		mov edx,[ebp+s_task.r_esi]
		add edx,[ebp+s_task.taskPageAddr]

		mov edi,0xA0000
		add edi,DWORD [edx]
		mov al,BYTE [edx+4]
		mov [edi],al

		xor eax,eax
		jmp Int_ScheduleCurr_succEax

;-----------------------------------------------------------------------------------------------

SysCall_FindTaskByName:
		mov ecx,[ebp+s_task.r_ecx]
		cmp ecx,(MAX_TASK_NAME+1)
		jc Sc_FindTaskByName0
		
		mov eax,RESULT_INCORRECT_SYSCALL_PARAMS
		jmp Int_ScheduleCurr_errEax

Sc_FindTaskByName0:
		mov esi,sc_findTaskName
		mov edi,sc_findTaskName+1
		mov ecx,MAX_TASK_NAME
		mov [esi],BYTE 0
		rep movsb

		mov esi,[ebp+s_task.r_esi]
		add esi,[ebp+s_task.taskPageAddr]
		mov edi,sc_findTaskName
		mov ecx,[ebp+s_task.r_ecx]

		jecxz Sc_FindTaskByName1
		rep movsb

Sc_FindTaskByName1:
		mov esi,sc_findTaskName

		push ebp
		call FindTaskByName
		pop ebp
		jnc Sc_FindTaskByName2

		mov eax,RESULT_TASK_NOT_FOUND
		jmp Int_ScheduleCurr_errEax

Sc_FindTaskByName2:
		jmp Int_ScheduleCurr_succEax

sc_findTaskName	times (MAX_TASK_NAME+1) db 0

;-----------------------------------------------------------------------------------------------

SysCall_RmodeInt:
		mov ecx,[ebp+s_task.r_ecx]
		cmp ecx,krnl_RmodeInt.msize
		jz Sc_RmodeInt0
		
		mov eax,RESULT_INCORRECT_SYSCALL_PARAMS
		jmp Int_ScheduleCurr_errEax

Sc_RmodeInt0:	mov esi,[ebp+s_task.r_esi]
		add esi,[ebp+s_task.taskPageAddr]

		mov ax,[esi+krnl_RmodeInt.r_ax]
		mov [rmode_ax],ax
		mov ax,[esi+krnl_RmodeInt.r_bx]
		mov [rmode_bx],ax
		mov ax,[esi+krnl_RmodeInt.r_cx]
		mov [rmode_cx],ax
		mov ax,[esi+krnl_RmodeInt.r_dx]
		mov [rmode_dx],ax
		mov ax,[esi+krnl_RmodeInt.r_si]
		mov [rmode_si],ax
		mov ax,[esi+krnl_RmodeInt.r_di]
		mov [rmode_di],ax
		mov ax,[esi+krnl_RmodeInt.r_bp]
		mov [rmode_bp],ax
		mov ax,[esi+krnl_RmodeInt.r_ds]
		mov [rmode_ds],ax
		mov ax,[esi+krnl_RmodeInt.r_es]
		mov [rmode_es],ax
		mov ax,[esi+krnl_RmodeInt.r_flags]
		mov [rmode_flags],ax

		mov al,[esi+krnl_RmodeInt.intNum]
		call RmodeInt

		mov edx,[ebp+s_task.r_edx]
		cmp edx,krnl_RmodeInt.msize
		jnc Sc_RmodeInt1

		mov eax,RESULT_BUFFER_TOO_SMALL
		jmp Int_ScheduleCurr_errEax

Sc_RmodeInt1:	mov edi,[ebp+s_task.r_edi]
		add edi,[ebp+s_task.taskPageAddr]

		mov ax,[esi+krnl_RmodeInt.intNum]
		mov [edi+krnl_RmodeInt.intNum],ax

		mov ax,[rmode_ax]
		mov [edi+krnl_RmodeInt.r_ax],ax
		mov ax,[rmode_bx]
		mov [edi+krnl_RmodeInt.r_bx],ax
		mov ax,[rmode_cx]
		mov [edi+krnl_RmodeInt.r_cx],ax
		mov ax,[rmode_dx]
		mov [edi+krnl_RmodeInt.r_dx],ax
		mov ax,[rmode_si]
		mov [edi+krnl_RmodeInt.r_si],ax
		mov ax,[rmode_di]
		mov [edi+krnl_RmodeInt.r_di],ax
		mov ax,[rmode_bp]
		mov [edi+krnl_RmodeInt.r_bp],ax
		mov ax,[rmode_ds]
		mov [edi+krnl_RmodeInt.r_ds],ax
		mov ax,[rmode_es]
		mov [edi+krnl_RmodeInt.r_es],ax
		mov ax,[rmode_flags]
		mov [edi+krnl_RmodeInt.r_flags],ax

		mov [ebp+s_task.r_eax],DWORD 0
		mov [ebp+s_task.r_ecx],DWORD krnl_RmodeInt.msize
		jmp Int_ScheduleCurr_succ

;-----------------------------------------------------------------------------------------------

SysCall_GetScanCode:
		movzx eax,WORD [globalKey]
		cmp [globalKeySet],BYTE 0
		jnz Sc_GetScanCode0
		jmp Int_ScheduleCurr_errEax

Sc_GetScanCode0:
		mov [globalKeySet],BYTE 0
		jmp Int_ScheduleCurr_succEax

;-----------------------------------------------------------------------------------------------

SysCall_EnumTasksID:
		mov eax,[ebp+s_task.r_ecx]
		and eax,eax
		jz Sc_EnumTasksID0

		mov eax,RESULT_INCORRECT_SYSCALL_PARAMS
		jmp Int_ScheduleCurr_errEax

Sc_EnumTasksID0:
		mov ecx,[tasksCount]
		mov eax,ecx
		shl eax,2
		cmp eax,[ebp+s_task.r_edx]
		jbe Sc_EnumTasksID1	; <=

		mov eax,RESULT_BUFFER_TOO_SMALL
		jmp Int_ScheduleCurr_errEax

Sc_EnumTasksID1:
		mov [ebp+s_task.r_ecx],eax
		jecxz Sc_EnumTasksID3

		mov esi,tasksList
		mov edi,[ebp+s_task.r_edi]
		add edi,[ebp+s_task.taskPageAddr]

Sc_EnumTasksID2:
		movzx ebx,BYTE [esi]
		imul ebx,s_task.msize
		add ebx,tasks

		mov eax,[ebx+s_task.taskID]
		stosd

		inc esi
		loop Sc_EnumTasksID2

Sc_EnumTasksID3:
		jmp Int_ScheduleCurr_succ

;-----------------------------------------------------------------------------------------------

SysCall_GetTaskName:
		mov eax,[ebp+s_task.r_ecx]
		cmp eax,4
		jz Sc_GetTaskName0

		mov eax,RESULT_INCORRECT_SYSCALL_PARAMS
		jmp Int_ScheduleCurr_errEax

Sc_GetTaskName0:
		mov eax,[ebp+s_task.r_edx]
		cmp eax,MAX_TASK_NAME+1
		jnc Sc_GetTaskName1

		mov eax,RESULT_BUFFER_TOO_SMALL
		jmp Int_ScheduleCurr_errEax

Sc_GetTaskName1:
		mov esi,[ebp+s_task.r_esi]
		add esi,[ebp+s_task.taskPageAddr]
		lodsd

		push ebp
		call FindTask
		jnc Sc_GetTaskName2

		pop ebp
		mov eax,RESULT_INVALID_TASKID
		jmp Int_ScheduleCurr_errEax

Sc_GetTaskName2:
		lea esi,[ebp+s_task.taskName]
		pop ebp

		mov edi,[ebp+s_task.r_edi]
		add edi,[ebp+s_task.taskPageAddr]
		mov ecx,MAX_TASK_NAME
		xor edx,edx

Sc_GetTaskName3:
		lodsb
		and al,al
		jz Sc_GetTaskName4
		stosb
		inc edx
		loop Sc_GetTaskName3

Sc_GetTaskName4:
		xor al,al
		stosb
		inc edx

		mov [ebp+s_task.r_ecx],edx
		jmp Int_ScheduleCurr_succ

;-----------------------------------------------------------------------------------------------

SysCall_KillTask:
		cmp [ebp+s_task.r_ecx],DWORD 4
		jz Sc_KillTask0

		mov eax,RESULT_INCORRECT_SYSCALL_PARAMS
		jmp Int_ScheduleCurr_errEax

Sc_KillTask0:	mov esi,[ebp+s_task.r_esi]
		add esi,[ebp+s_task.taskPageAddr]

		lodsd
		cmp eax,[ebp+s_task.taskID]
		jnz Sc_KillTask1
		jmp Sc_Exit_

Sc_KillTask1:	push ebp
		call KillTask
		pop ebp
		jnc Sc_KillTask2

		mov eax,RESULT_INVALID_TASKID
		jmp Int_ScheduleCurr_errEax

Sc_KillTask2:	mov eax,[ebp+s_task.taskID]
		call FindTask
		mov [currentTaskN],eax

		xor eax,eax
		jmp Int_ScheduleCurr_succEax

;-----------------------------------------------------------------------------------------------

SysCall_Exit:	mov eax,[ebp+s_task.r_ecx]
		and eax,eax
		jz Sc_Exit_

		mov eax,RESULT_INCORRECT_SYSCALL_PARAMS
		jmp Int_ScheduleCurr_errEax

Sc_Exit_:	mov eax,[ebp+s_task.taskID]
		call KillTask

		dec DWORD [currentTaskN]
		jmp Schedule

;-----------------------------------------------------------------------------------------------

dummy		dd 0

SysCall_CreateTask:
		mov ebx,[ebp+s_task.r_ecx]
		cmp ebx,krnl_CreateTask.msize+1
		jnc Sc_CreateTask0

		mov eax,RESULT_INCORRECT_SYSCALL_PARAMS
		jmp Int_ScheduleCurr_errEax

Sc_CreateTask0: mov esi,[ebp+s_task.r_esi]
		add esi,[ebp+s_task.taskPageAddr]

		mov ecx,[esi+krnl_CreateTask.stackSize]
		mov edx,[esi+krnl_CreateTask.dataSize]

		push eax			;;
		mov eax,[ebp+s_task.r_edi]	;;
		cmp eax,0x12345678		;;
		jnz gg1				;;
		mov eax,1			;;
		mov [dummy],eax			;;
		gg1: pop eax			;;

		mov eax,esi
		add eax,krnl_CreateTask.taskCode
		sub ebx,krnl_CreateTask.taskCode
		push ebp
		call CreateTask
		pop ebp

		push eax			;;
		mov eax,[ebp+s_task.r_edi]	;;
		cmp eax,0x12345678		;;
		jnz gg				;;
		mov ax,0x1111			;;
		mov ds,ax			;;
		gg: pop eax			;;

		xor eax,eax
		jmp Int_ScheduleCurr_succEax
