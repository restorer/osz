[BITS 32]
		align 4
Begin32c:	mov ax,kernel_data-_GDT
		mov ds,ax
		mov es,ax
		mov fs,ax
		mov gs,ax
		mov ss,ax
		mov esp,0x2FFFF

		call TestMemory

		mov edi,memMap		; 1 мег занят системой.
		mov ecx,0x100 / 32
		xor eax,eax
		dec eax
		rep stosd

		mov ecx,0x20000/4 - (0x100/32)	; остальные свободны
		xor eax,eax
		rep stosd

		; TIMER SET TO 1/100 S
		mov al,0x34	; set to 100Hz
		out 0x43,al
		mov al,0x9b	; lsb 1193180 / 1193
		out 0x40,al
		mov al,0x2e	; msb
		out 0x40,al

		call EnableIRQs
