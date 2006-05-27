%define exec_RunProgramm	1

		struc sexec_RunProgramm
.taskName	resb MAX_TASK_NAME+1
.fileName	resb 0x100
.msize
		endstruc
