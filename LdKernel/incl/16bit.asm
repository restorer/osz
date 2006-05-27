[BITS 16]
[ORG KERNEL_START]

Start:		mov ax,cs
		mov ds,ax
		mov es,ax
		mov ss,ax
		mov sp,0x0000

	; ---- Go to protected mode ----

		cli
		cld
		call PrepareIRQs
		call A20En

		lgdt [_GDT-KERNEL_START]	; load GDT
		lidt [_IDTR-KERNEL_START]	; load IDT

; CR0 :: PG CD NW 0		31..28
;        0 0 0 0		27..24
;        0 0 0 0		23..20
;        0 AM 0 WP		19..16
;        0 0 0 0		15..12
;        0 0 0 0		11..8
;        0 0 NE ET		7..4
;        TS EM MP PE		3..0

		mov eax,cr0
		or eax, 00000000000000000000000000000001b
		and eax,10011111111110101111111111111111b
		mov cr0,eax
		jmp DWORD (kernel_code-_GDT):Begin32c
