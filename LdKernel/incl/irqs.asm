EnableIRQs:	mov al,0x11	; icw4, edge triggered
		out MASTER_PIC,al
		jmp short $+2
		out SLAVE_PIC,al
		jmp short $+2

		mov al,0x20	; generate 0x20+
		out IRQ_LO_PORT,al
		jmp short $+2
		mov al,0x28	; generate 0x28+
		out IRQ_HI_PORT,al
		jmp short $+2

		mov al,0x04	; slave at irq2
		out IRQ_LO_PORT,al
		jmp short $+2
		mov al,0x02	; at irq9
		out IRQ_HI_PORT,al
		jmp short $+2

		mov al,0x01	; 8086 mode
		out IRQ_LO_PORT,al
		jmp short $+2
		out IRQ_HI_PORT,al
		jmp short $+2

		mov al,0xFF	; mask all IRQs
		out IRQ_LO_PORT,al
		jmp short $+2
		out IRQ_HI_PORT,al
		jmp short $+2
;;;;
		xor al,al	; unmask all IRQs
		out IRQ_HI_PORT,al
		jmp short $+2
		out IRQ_LO_PORT,al
		jmp short $+2

		mov ecx,32
EnableIRQs0:	mov al,END_OF_INTERR	; ready for IRQs
		out MASTER_PIC,al
		jmp short $+2
		out MASTER_PIC,al
		out SLAVE_PIC,al
		loop EnableIRQs0	; flush the queue

EnableIRQs1:	in al,KBD_PORT_C	; flush keyboard buffer
		test al,0x01
		jz EnableIRQs2
		in al,KBD_PORT_A
		jmp short EnableIRQs1
EnableIRQs2:	test al,0x02
		jnz EnableIRQs1

		in al,KBD_PORT_B	; enable keyboard
		mov ah,al
		or al,0x80
		out KBD_PORT_B,al
		jmp short $+2
		mov al,ah
		out KBD_PORT_B,al
		jmp short $+2

		sti
		ret

;---------------------------------------------------------------------------------------------

PrepareIRQs:	mov al,0xFF	; mask all IRQs
		out IRQ_HI_PORT,al
		out IRQ_LO_PORT,al

		in al,0x70	; disable NMI
		or al,0x80
		out 0x70,al
		ret

A20En:		in al,0x92	; enable A20
		or al,2
		out 0x92,al
		ret

;---------------------------------------------------------------------------------------------

RestoreRmodeIRQs:
		mov al,0xFF	; mask all IRQs
		out IRQ_HI_PORT,al
		out IRQ_LO_PORT,al

		mov al,0x11	; icw4, edge triggered
		out MASTER_PIC,al
		jmp short $+2
		out SLAVE_PIC,al
		jmp short $+2

		mov al,8	; generate 8+
		out IRQ_LO_PORT,al
		jmp short $+2
		mov al,0x10	; generate 0x10+
		out IRQ_HI_PORT,al
		jmp short $+2

		mov al,0x04	; slave at irq2
		out IRQ_LO_PORT,al
		jmp short $+2
		mov al,0x02	; at irq9
		out IRQ_HI_PORT,al
		jmp short $+2

		mov al,0x01	; 8086 mode
		out IRQ_LO_PORT,al
		jmp short $+2
		out IRQ_HI_PORT,al
		jmp short $+2

		mov al,0xFF	; mask all IRQs
		out IRQ_LO_PORT,al
		jmp short $+2
		out IRQ_HI_PORT,al
		jmp short $+2

		xor al,al	; unmask all IRQs
		out IRQ_HI_PORT,al
		jmp short $+2
		out IRQ_LO_PORT,al
		jmp short $+2

		mov ecx,32
RestoreRmodeIRQs0:
		mov al,END_OF_INTERR	; ready for IRQs
		out MASTER_PIC,al
		jmp short $+2
		out MASTER_PIC,al
		out SLAVE_PIC,al
		loop RestoreRmodeIRQs0	; flush the queue
		ret
