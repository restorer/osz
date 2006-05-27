gp_except_tx	db "Exception "
gp_except_txN	db ".."
		db ", "
gp_except_txS	db "...."
		db ":"
gp_except_txO	db "........"
		db " code "
gp_except_txC	db "........"
		db 0

except_bk	dd 0x12345678

Exception:
		push eax
		mov ax,kernel_data-_GDT
		mov ds,ax
		mov es,ax

		pop eax
		mov [except_bk],eax
		pop ax		; exception number

		pushad
		push es
		push fs
		push gs
		mov edi,gp_except_txN
		call PrintHexByte
		pop gs
		pop fs
		pop es
		popad

		pushad
		push es
		push fs
		push gs
		mov edi,gp_except_txC
		mov al,'#'
		mov ecx,8
		rep stosb
		pop gs
		pop fs
		pop es
		popad

		pop eax	; Offset
		pushad
		push es
		push fs
		push gs
		mov edi,gp_except_txO
		call PrintHexDword
		pop gs
		pop fs
		pop es
		popad

		pop ax	; Selector
		pushad
		push es
		push fs
		push gs
		mov edi,gp_except_txS
		call PrintHexWord
		pop gs
		pop fs
		pop es
		popad

		mov [gp_print_tx], DWORD gp_except_tx
		mov eax,[except_bk]
		jmp GP_FAULT

;;;;

ExceptionC:   	push eax
		mov ax,kernel_data-_GDT
		mov ds,ax
		mov es,ax

		pop eax
		mov [except_bk],eax
		pop ax		; exception number

		pushad
		push es
		push fs
		push gs
		mov edi,gp_except_txN
		call PrintHexByte
		pop gs
		pop fs
		pop es
		popad

		pop eax	; Exception code
		pushad
		push es
		push fs
		push gs
		mov edi,gp_except_txC
		call PrintHexDword
		pop gs
		pop fs
		pop es
		popad

		pop eax	; Offset
		pushad
		push es
		push fs
		push gs
		mov edi,gp_except_txO
		call PrintHexDword
		pop gs
		pop fs
		pop es
		popad

		pop ax	; Selector
		pushad
		push es
		push fs
		push gs
		mov edi,gp_except_txS
		call PrintHexWord
		pop gs
		pop fs
		pop es
		popad

		mov [gp_print_tx], DWORD gp_except_tx
		mov eax,[except_bk]
		jmp GP_FAULT

;-------------------------------------------------------------------------------

Except_00:	cli
		push WORD 0x00
		jmp Exception

Except_01:	cli
		push WORD 0x01		; не обл. св-вом повт. запускаемости
		jmp Exception

Except_02:	cli
		push WORD 0x02
		jmp Exception

Except_03:	cli
		push WORD 0x03
		jmp Exception

Except_04:	cli
		push WORD 0x04
		jmp Exception

Except_05:	cli
		push WORD 0x05
		jmp Exception

Except_06:	cli
		push WORD 0x06
		jmp Exception

Except_07:	cli
		push WORD 0x07
		jmp Exception

Except_08:	cli
		push WORD 0x08	; не обл. св-вом повт. запускаемости
		jmp ExceptionC

Except_09:	cli
		push WORD 0x09	; не обл. св-вом повт. запускаемости
		jmp Exception

Except_0A:	cli
		push WORD 0x0A
		jmp ExceptionC

Except_0B:	cli
		push WORD 0x0B
		jmp ExceptionC

Except_0C:	cli
		push WORD 0x0C
		jmp ExceptionC

Except_0D:	cli
		push WORD 0x0D	; не обл. св-вом повт. запускаемости
		jmp ExceptionC

Except_0E:	cli
		push WORD 0x0E
		jmp Exception

Except_0F:	cli
		push WORD 0x0F
		jmp Exception

Except_10:	cli
		push WORD 0x10	; не обл. св-вом повт. запускаемости
		jmp Exception

Except_11:	cli
		push WORD 0x11
		jmp Exception

Except_12:	cli
		push WORD 0x12
		jmp Exception

Except_13:	cli
		push WORD 0x13
		jmp Exception

Except_14:	cli
		push WORD 0x14
		jmp Exception

Except_15:	cli
		push WORD 0x15
		jmp Exception

Except_16:	cli
		push WORD 0x16
		jmp Exception

Except_17:	cli
		push WORD 0x17
		jmp Exception

Except_18:	cli
		push WORD 0x18
		jmp Exception

Except_19:	cli
		push WORD 0x19
		jmp Exception

Except_1A:	cli
		push WORD 0x1A
		jmp Exception

Except_1B:	cli
		push WORD 0x1B
		jmp Exception

Except_1C:	cli
		push WORD 0x1C
		jmp Exception

Except_1D:	cli
		push WORD 0x1D
		jmp Exception

Except_1E:	cli
		push WORD 0x1E
		jmp Exception

Except_1F:	cli
		push WORD 0x1F
		jmp Exception
