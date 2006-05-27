;-------------------------------------------------------------------------------

IRQ_Dummy_M:	push ax
		mov al,END_OF_INTERR
		out MASTER_PIC,al
		pop ax
		sti
		iret

IRQ_Dummy_S:	push ax
		mov al,END_OF_INTERR
		out MASTER_PIC,al
		out SLAVE_PIC,al
		pop ax
		sti
		iret

;-------------------------------------------------------------------------------
;;;; Timer

IRQ_0:		cli
		push ax
		push ds
		mov ax,kernel_data-_GDT
		mov ds,ax

		inc DWORD [globalTime]

		mov eax,[taskRunningTime]
		dec eax
		mov [taskRunningTime],eax
		jz IRQ_0_Switch

		pop ds
		pop ax
		jmp IRQ_Dummy_M

IRQ_0_Switch:	mov al,END_OF_INTERR
		out MASTER_PIC,al
		pop ds
		pop ax

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

		; switch to next task

; WHAT DA FUCK?
;		xor eax,eax
;		mov [ebp+s_task.r_eax],eax
;		mov [ebp+s_task.r_ecx],eax
;		and [ebp+s_task.r_eflags],DWORD CF_AND

		jmp Schedule

;-------------------------------------------------------------------------------
;;;; Keyboard

IRQ_1:		cli
		push ax
		push ds
		mov ax,kernel_data-_GDT
		mov ds,ax

		mov al,[irq_1_extscan]
		and al,al
		jz IRQ_1_Normal

		cmp al,0xE1	; check for 'Pause' key
		jz IRQ_1_Pause

		in al,KBD_PORT_A
		cmp al,0x2A	; Prefix
		jz IRQ_1_Clr
		cmp al,0xAA	; event.keyup
		jz IRQ_1_Clr

IRQ_1_ExtPut:	mov ah,[irq_1_extscan]
IRQ_1_Put:	mov [globalKey],ax
		or [globalKeySet],BYTE 1
		jmp short IRQ_1_Clr

IRQ_1_Pause:	in al,KBD_PORT_A
		cmp al,0xC5	; 'Pause' key
		jz IRQ_1_ExtPut
		cmp al,0x45	; ?
		jz IRQ_1_ExtPut
		jmp short IRQ_1_Exit

IRQ_1_Normal:	in al,KBD_PORT_A
		cmp al,0xFE	; Ignore it
		jz IRQ_1_Exit
		cmp al,0xE1	; Extended scan code
		jz IRQ_1_ExtKey
		cmp al,0xE0	; Extended scan code
		jz IRQ_1_ExtKey

		xor ah,ah
		jmp short IRQ_1_Put

IRQ_1_ExtKey:	mov [irq_1_extscan],al

IRQ_1_Exit:	in al,KBD_PORT_B
		mov ah,al
		or al,0x80
		out KBD_PORT_B,al
		mov al,ah
		out KBD_PORT_B,al

		pop ds
		pop ax
		jmp IRQ_Dummy_S

IRQ_1_Clr:	xor al,al
		mov [irq_1_extscan],al
		jmp short IRQ_1_Exit

irq_1_extscan	db 0

;-------------------------------------------------------------------------------

IRQ_2:	     	cli
		jmp IRQ_Dummy_M

IRQ_3:	     	cli
		jmp IRQ_Dummy_M

IRQ_4:	     	cli
		jmp IRQ_Dummy_M

IRQ_5:	     	cli
		jmp IRQ_Dummy_M

IRQ_6:	     	cli
		jmp IRQ_Dummy_M

IRQ_7:	     	cli
		jmp IRQ_Dummy_M

IRQ_8:	     	cli
		jmp IRQ_Dummy_S

IRQ_9:	     	cli
		jmp IRQ_Dummy_S

IRQ_10:	     	cli
		jmp IRQ_Dummy_S

IRQ_11:	     	cli
		jmp IRQ_Dummy_S

IRQ_12:	     	cli
		jmp IRQ_Dummy_S

IRQ_13:	     	cli
		jmp IRQ_Dummy_S

IRQ_14:	     	cli
		jmp IRQ_Dummy_S

IRQ_15:	     	cli
		jmp IRQ_Dummy_S
