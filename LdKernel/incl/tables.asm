_GDT		;; first element of GDT not use. Used as _GDTR
		dw _GDT_END-_GDT-1
		dd _GDT
		dw 0

		; limit 00..15
		; base 00..15
		; base 16..23   /-- limit 16..19
		; G D 0 AVL LIMIT(4) P DPL(2) S TYPE(3) A
		; base 24..31

		;; kernel code
kernel_code	dw 0xFFFF
		dw 0x0000
		db 0x00
		dw ACC_GRANULARY | ACC_DEF32SIZE | (1111b * ACC_LIMIT_MUL) | ACC_PRESENT | ACC_DPL_RING0 | ACC_TYPE_CODE | ACC_TYPE_READ | ACC_USERSEG
		db 0x00

		;; kernel data
kernel_data	dw 0xFFFF
		dw 0x0000
		db 0x00
		dw ACC_GRANULARY | ACC_DEF32SIZE | (1111b * ACC_LIMIT_MUL) | ACC_PRESENT | ACC_DPL_RING0 | ACC_TYPE_DATA | ACC_TYPE_WRITE | ACC_USERSEG
		db 0x00

		;; used when return to real mode
real_mode_code	dw 0xFFFF
		dw 0x0000
		db KERNEL_START_HI
		dw ACC_PRESENT | ACC_DPL_RING0 | ACC_TYPE_CODE | ACC_TYPE_READ | ACC_USERSEG
		db 0x00

		;; used when return to real mode
real_mode_data	dw 0xFFFF
		dw 0x0000
		db KERNEL_START_HI
		dw ACC_PRESENT | ACC_DPL_RING0 | ACC_TYPE_DATA | ACC_TYPE_WRITE | ACC_USERSEG
		db 0x00

		;; task code
task_code	dw 0x0000
		dw 0x0000
		db 0x00
		dw ACC_GRANULARY | ACC_DEF32SIZE | (0000b * ACC_LIMIT_MUL) | ACC_PRESENT | ACC_DPL_RING0 | ACC_TYPE_CODE | ACC_TYPE_READ | ACC_USERSEG
		db 0x00

		;; task data
task_data	dw 0x0000
		dw 0x0000
		db 0x00
		dw ACC_GRANULARY | ACC_DEF32SIZE | (0000b * ACC_LIMIT_MUL) | ACC_PRESENT | ACC_DPL_RING0 | ACC_TYPE_DATA | ACC_TYPE_WRITE | ACC_USERSEG
		db 0x00

_GDT_END

;;;;====;;;;====

_RM_IDTR	dw 0x400-1
		dd 0x00000000
		dw 0

;;;;====;;;;====

_IDTR		dw _IDT_END-_IDT-1
		dd _IDT

_IDT		; dw offsetLo
		; dw selector
		; db paramsCount
		; db access
		; dw offsetHi

		dw Except_00-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_01-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_02-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_03-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_04-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_05-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_06-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_07-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_08-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_09-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_0A-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_0B-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_0C-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_0D-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_0E-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_0F-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_10-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_11-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_12-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_13-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_14-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_15-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_16-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_17-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_18-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_19-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_1A-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_1B-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_1C-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_1D-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_1E-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Except_1F-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_TRAPGATE | ACC_PRESENT
		dw KERNEL_START_HI
;;;; int 20
		dw IRQ_0-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_1-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_2-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_3-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_4-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_5-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_6-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_7-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_8-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_9-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_10-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_11-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_12-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_13-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_14-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw IRQ_15-KERNEL_START
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI
;;;; int 30
		dw Int_GetMessage-KERNEL_START		; 0x30
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Int_SendMessageW-KERNEL_START	; 0x31
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Int_ProcessMessage-KERNEL_START	; 0x32
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Int_RemoveMessage-KERNEL_START	; 0x33
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

		dw Int_SendAnswer-KERNEL_START		; 0x34
		dw kernel_code-_GDT
		db 0
		db ACC_INTGATE | ACC_PRESENT
		dw KERNEL_START_HI

_IDT_END

;-------------------------------------------------------------------------------

memMap		equ $			; Memory map, 128kb
memMapEnd	equ memMap+0x20000

;-------------------------------------------------------------------------------

tasksList	equ memMapEnd
tasksListEnd	equ tasksList+MAX_TASKS

tasks		equ tasksListEnd
tasksEnd	equ tasks+MAX_TASKS*s_task.msize
