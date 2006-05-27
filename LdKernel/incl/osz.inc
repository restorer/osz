%define	MAX_TASK_NAME	32

;--------------------------------------------------------------------------------------------

%define i_GetMessage		0x30
%define i_SendMessageW		0x31
%define i_ProcessMessage	0x32
%define i_RemoveMessage		0x33
%define i_SendAnswer		0x34

;--------------------------------------------------------------------------------------------

%define msg_Sleep		0
%define msg_GetTickCount	1
%define msg_FindTaskByName	2
%define msg_RmodeInt		3
%define msg_EnumTasksID		4
%define msg_GetTaskName		5
%define msg_KillTask		6
%define msg_Exit		7
%define msg_CreateTask		8

%define msg_SetPixel		100
%define msg_GetScanCode		101

;--------------------------------------------------------------------------------------------

		struc krnl_RmodeInt
.intNum:	resb 1
.r_ax:
.r_al:		resb 1
.r_ah:		resb 1
.r_bx:
.r_bl:		resb 1
.r_bh:		resb 1
.r_cx:
.r_cl:		resb 1
.r_ch:		resb 1
.r_dx:
.r_dl:		resb 1
.r_dh:		resb 1
.r_si:		resw 1
.r_di:		resw 1
.r_bp:		resw 1
.r_ds:		resw 1
.r_es:		resw 1
.r_flags:	resw 1

.msize:
		endstruc

;--------------------------------------------------------------------------------------------

		struc krnl_CreateTask
.taskName	resb MAX_TASK_NAME+1
.stackSize	resd 1
.dataSize	resd 1
.taskCode
.msize
		endstruc

;--------------------------------------------------------------------------------------------
