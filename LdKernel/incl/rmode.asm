;-----------------------------------------------------------------------------------
;;;; IN: AL - interrupt number
;;;;     [rmode_ax] .... [rmode_flags] - real mode registers
;;;;
;;;; OUT: [rmode_ax] .... [rmode_flags] - real mode registers

RmodeInt:	pushad
		push es
		push fs
		push gs

		mov [RmodeIntNum],al
		mov ax,ss
		mov [RmodeInt_ss],ax
		mov [RmodeInt_esp],esp

		xor eax,eax
		mov cr3,eax
		jmp DWORD (real_mode_code-_GDT):(RmodeInt0-KERNEL_START)
[BITS 16]
		align 2
RmodeInt0:	cli
		cld
		call PrepareIRQs

		mov ax,real_mode_data-_GDT
		mov ds,ax
		mov es,ax
		mov ss,ax
		mov fs,ax
		mov gs,ax
		lidt [_RM_IDTR]

		mov eax,cr0
		and al,0xFE
		mov cr0,eax
		jmp WORD KERNEL_START_SEG:(RmodeInt1-KERNEL_START)

		align 2
RmodeInt1:	mov ax,0x1000
		mov ss,ax
		mov sp,0

		call RestoreRmodeIRQs

		mov ax,[cs:(rmode_ax-KERNEL_START)]
		mov bx,[cs:(rmode_bx-KERNEL_START)]
		mov cx,[cs:(rmode_cx-KERNEL_START)]
		mov dx,[cs:(rmode_dx-KERNEL_START)]
		mov si,[cs:(rmode_si-KERNEL_START)]
		mov di,[cs:(rmode_di-KERNEL_START)]
		mov bp,[cs:(rmode_bp-KERNEL_START)]
		mov ds,[cs:(rmode_ds-KERNEL_START)]
		mov es,[cs:(rmode_es-KERNEL_START)]

		push WORD [cs:(rmode_flags-KERNEL_START)]
		popf

		sti

		db 0xCD
RmodeIntNum	db 0x00

		cli

		pushf
		pop WORD [cs:(rmode_flags-KERNEL_START)]

		mov [cs:(rmode_es-KERNEL_START)],es
		mov [cs:(rmode_ds-KERNEL_START)],ds
		mov [cs:(rmode_bp-KERNEL_START)],bp
		mov [cs:(rmode_di-KERNEL_START)],di
		mov [cs:(rmode_si-KERNEL_START)],si
		mov [cs:(rmode_dx-KERNEL_START)],dx
		mov [cs:(rmode_cx-KERNEL_START)],cx
		mov [cs:(rmode_bx-KERNEL_START)],bx
		mov [cs:(rmode_ax-KERNEL_START)],ax

		cli
		cld
		call PrepareIRQs
		call A20En

		mov eax,cr0
		or al,1
		mov cr0,eax
		jmp DWORD (kernel_code-_GDT):RmodeInt2
[BITS 32]
		align 4
RmodeInt2:	mov ax,kernel_data-_GDT
		mov ds,ax
		mov es,ax
		mov fs,ax
		mov gs,ax

		mov ax,0x1234
RmodeInt_ss	equ $-2
		mov ss,ax
		mov esp,0x12345678
RmodeInt_esp	equ $-4

		lidt [_IDTR]
		call EnableIRQs

		pop gs
		pop fs
		pop es
		popad
		ret

rmode_ax
rmode_al	db 0
rmode_ah	db 0
rmode_bx
rmode_bl	db 0
rmode_bh	db 0
rmode_cx
rmode_cl	db 0
rmode_ch	db 0
rmode_dx
rmode_dl	db 0
rmode_dh	db 0
rmode_si	dw 0
rmode_di	dw 0
rmode_bp	dw 0
rmode_ds	dw 0
rmode_es	dw 0
rmode_flags	dw 0
