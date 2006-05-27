;-------------------------------------------------------------------------------
;;;; IN: ESI - ptrString

GpFault:	mov [gp_print_tx],esi

GP_FAULT:	pushfd
		mov [gp_eax],eax
		mov [gp_ebx],ebx
		mov [gp_ecx],ecx
		mov [gp_edx],edx
		mov ax,cs
		mov [gp_cs],ax
		mov ax,ds
		mov [gp_ds],ax
		mov ax,es
		mov [gp_es],ax
		mov ax,fs
		mov [gp_fs],ax
		mov ax,gs
		mov [gp_gs],ax
		pop eax
		mov [gp_eflags],eax
		mov [gp_ebp],ebp
		mov [gp_esp],esp
		mov [gp_esi],esi
		mov [gp_edi],edi

		cli
		cld

		mov al,0xFF	; mask all IRQs
		out IRQ_HI_PORT,al
		out IRQ_LO_PORT,al

		in al,0x70	; disable NMI
		or al,0x80
		out 0x70,al

		mov [rmode_ax], WORD 0x03
		mov al,0x10
		call RmodeInt

		cli

		mov esi,[gp_print_tx]
		mov edi,0xB8000
		mov ah,0x4F
		call PrintText

		mov esi,gp_regs_tx
		mov edi,0xB8000+320
		mov ebp,gp_eflags

		mov ecx,9

GP_FAULT0:	push ecx
		push edi

		mov ah,8+2
		call PrintText

		push edi
		mov eax,[ds:ebp]
		add ebp,4
		mov edi,gp_dword_tx
		call PrintHexDword
		pop edi

		push esi
		mov esi,gp_dword_tx
		mov ah,7
		call PrintText
		pop esi

		pop edi
		pop ecx

		add edi,160
		loop GP_FAULT0
;;;;
		mov ecx,5

GP_FAULT1:	push ecx
		push edi

		mov ah,8+2
		call PrintText

		push edi
		mov eax,[ds:ebp]
		inc ebp
		inc ebp
		mov edi,gp_word_tx
		call PrintHexWord
		pop edi

		push esi
		mov esi,gp_word_tx
		mov ah,7
		call PrintText
		pop esi

		pop edi
		pop ecx

		add edi,160
		loop GP_FAULT1

		jmp short $

gp_print_tx	dd 0x12345678

gp_dword_tx	db "...."
gp_word_tx	db "....",0

gp_regs_tx	db "EFLAGS = ", 0
		db "   EAX = ", 0
		db "   EBX = ", 0
		db "   ECX = ", 0
		db "   EDX = ", 0
		db "   ESI = ", 0
		db "   EDI = ", 0
		db "   EBP = ", 0
		db "   ESP = ", 0
		db "    CS = ", 0
		db "    DS = ", 0
		db "    ES = ", 0
		db "    FS = ", 0
		db "    GS = ", 0

gp_eflags	dd 0
gp_eax		dd 0
gp_ebx		dd 0
gp_ecx		dd 0
gp_edx		dd 0
gp_esi		dd 0
gp_edi		dd 0
gp_ebp		dd 0
gp_esp		dd 0
gp_cs		dw 0
gp_ds		dw 0
gp_es		dw 0
gp_fs		dw 0
gp_gs		dw 0
