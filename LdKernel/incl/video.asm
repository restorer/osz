;-----------------------------------------------------------------------------------
;;;; IN: AL = {0, text 80x25} {1, 320x200x256}

SetVideoMode:	and al,al
		jnz SetVideoMode0

		mov [rmode_ax], WORD 0x03
		mov al,0x10
		jmp RmodeInt

SetVideoMode0:	dec al
		jnz SetVideoMode1

		mov [rmode_ax], WORD 0x13
		mov al,0x10
		jmp RmodeInt

SetVideoMode1:	ret
