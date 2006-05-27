%include "incl/macro.inc"
%include "incl/osz.inc"
%include "incl/console_library.inc"

		db "OSZEXE.0"		; Executable file revision 0 id
		dd 0x1000		; Stack size
		dd _DATA_LEN		; Data size

[ORG -0x10]
[BITS 32]

		mov [DAT+putZero0],BYTE 0
		call Init
		call PrintTextBuf
		call BlitScreen

Start:		mov edi,DAT+msgBuf
		mov edx,msgBufE-msgBuf
		int i_GetMessage
		jnz Process

		xor ebx,ebx
		xor ecx,ecx
		xor edx,edx
		mov eax,msg_Sleep
		int i_SendMessageW
		jmp Start

;---------------------------------------------------------------------------------------

Process:	cmp eax,cons_Clear
		jnz Process0
		jmp MSG_Clear
Process0:	cmp eax,cons_PrintSymbol
		jnz Process1
		jmp MSG_PrintSymbol
Process1:	cmp eax,cons_SetTextColor
		jnz Process2
		jmp MSG_SetTextColor
Process2:	cmp eax,cons_PrintChar
		jnz Process3
		jmp MSG_PrintChar
Process3:	cmp eax,cons_PrintString
		jnz Process4
		jmp MSG_PrintString
Process4:	cmp eax,cons_PrintNumber
		jnz Process5
		jmp MSG_PrintNumber
Process5:	cmp eax,cons_RmBackImg
		jnz Process6
		jmp MSG_RmBackImg
Process6:	cmp eax,cons_SetBackImg
		jnz Process7
		jmp MSG_SetBackImg
Process7:
		mov eax,1
		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

;---------------------------------------------------------------------------------------

MSG_SetBackImg:	cmp ecx,0xFC00
		jz MSG_SetBackImg0
		jmp StdParamsErr

MSG_SetBackImg0:
		mov esi,DAT+msgBuf
		mov edi,DAT+palette
		mov ecx,0x300/4
		rep movsd

		mov edi,DAT+picBuf
		mov ecx,320*200/4
		rep movsd

		mov [DAT+backImg], BYTE 1

		call InitPalette
		call PrintTextBuf
		call BlitScreen
		jmp StdProcessMsg

;---------------------------------------------------------------------------------------

MSG_RmBackImg:	and ecx,ecx
		jz MSG_RmBackImg0
		jmp StdParamsErr

MSG_RmBackImg0:	mov [DAT+backImg], BYTE 0

		call PrintTextBuf
		call BlitScreen
		jmp StdProcessMsg

;---------------------------------------------------------------------------------------

MSG_PrintNumber:
		cmp ecx,1+2		; only hex words are supported now
		jz MSG_PrintNumber0
		cmp ecx,1+4
		jz MSG_PrintNumber1
		jmp StdParamsErr

MSG_PrintNumber0:
		mov ax,[DAT+msgBuf+1]
		mov edi,numPrintBuf+2+4
		call PrintHexWord
		mov esi,numPrintBuf+2+4
		jmp MSG_PrintNumber2

MSG_PrintNumber1:
		mov eax,[DAT+msgBuf+1]
		mov edi,numPrintBuf+2
		call PrintHexDword
		mov esi,numPrintBuf+2

MSG_PrintNumber2:
		call PrintString
		call PrintTextBuf
		call BlitScreen
		jmp StdProcessMsg
		
;---------------------------------------------------------------------------------------

MSG_PrintString:
		mov edi,DAT+msgBuf
		mov esi,edi
		add edi,ecx
		xor al,al
		stosb
		call PrintString
		call PrintTextBuf
		call BlitScreen
		jmp StdProcessMsg

;---------------------------------------------------------------------------------------

MSG_PrintChar:	cmp ecx,1
		jz MSG_PrintChar0
		jmp StdParamsErr

MSG_PrintChar0:	mov al,[DAT+msgBuf]
		call PrintChar
		call PrintTextBuf
		call BlitScreen
		jmp StdProcessMsg

;---------------------------------------------------------------------------------------

MSG_SetTextColor:
		cmp ecx,1
		jz MSG_SetTextColor0
		jmp StdParamsErr

MSG_SetTextColor0:
		mov al,[DAT+msgBuf]
		mov [DAT+textColor],al
		jmp StdProcessMsg

;---------------------------------------------------------------------------------------

MSG_PrintSymbol:
		cmp ecx,1
		jz MSG_PrintSymbol0
		jmp StdParamsErr

MSG_PrintSymbol0:
		mov al,[DAT+msgBuf]
		call PrintSym
		call PrintTextBuf
		call BlitScreen
		jmp StdProcessMsg

;---------------------------------------------------------------------------------------

MSG_Clear:	and ecx,ecx
		jz MSG_Clear0
		jmp StdParamsErr

MSG_Clear0:	call Clear
		jmp StdProcessMsg

;---------------------------------------------------------------------------------------

StdParamsErr:	mov eax,2
		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

StdProcessMsg:	xor eax,eax
		xor ecx,ecx
		int i_ProcessMessage
		jmp Start

;---------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------

PrintString:	lodsb
		and al,al
		jnz PrintString0
		ret

PrintString0:	push esi
		call PrintChar
		pop esi
		jmp PrintString

;---------------------------------------------------------------------------------------
;;;; IN: AL - number, EDI - bufferPtr[2]
;;;; OUT: hex number in ptrBuffer
;;;; MODIFY: AL, CL, EBX, ESI, EDI

PrintHexByte:	mov ebx,hexTab
		mov cl,al
		shr al,4
		xlatb
		stosb
		mov al,cl
		and al,0x0F
		xlatb
		stosb
		ret

;;;; IN: AX - number, EDI - bufferPtr[4]
;;;; OUT: hex number in ptrBuffer
;;;; MODIFY: AL, CX, EBX, ESI, EDI
PrintHexWord:	mov ch,al
		mov al,ah
		call PrintHexByte
		mov al,ch
		jmp PrintHexByte

;;;; IN: EAX - number, EDI - bufferPtr[4]
;;;; OUT: hex number in ptrBuffer
;;;; MODIFY: EAX, CX, EBX, ESI, EDI
PrintHexDword:	push ax
		shr eax,0x10
		call PrintHexWord
		pop ax
		jmp PrintHexWord

hexTab		db "0123456789ABCDEF"

;-------------------------------------------------------------------------------

PrintChar:	cmp al,8
		jnz PrintChar0

		call CursorBack
		xor al,al
		call PrintSym
		jmp CursorBack

PrintChar0:	cmp al,9
		jnz PrintChar1
		jmp Tabulation

PrintChar1:	cmp al,0x0A
		jnz PrintChar2
		ret

PrintChar2:	cmp al,0x0D
		jnz PrintChar3
		jmp NewLine

PrintChar3:	jmp PrintSym

;---------------------------------------------------------------------------------------

Tabulation:	mov al,[DAT+cursorY]
		cmp al,[DAT+heightCh]
		jc Tabulation0

		mov al,[DAT+heightCh]	; не обязательно, но всё таки
		dec al
		mov [DAT+cursorY],al

		call ScrollUp

Tabulation0:	movzx ax,[DAT+cursorX]
		mov bl,[DAT+tabSize]
		add al,bl
		cmp al,[DAT+widthCh]
		jc Tabulation1

		inc BYTE [DAT+cursorY]
		xor bh,bh
		jmp Tabulation2

Tabulation1:	mov bh,al
		div bl
		sub bh,ah

Tabulation2:	mov [DAT+cursorX],bh
		ret

;---------------------------------------------------------------------------------------

NewLine:	mov al,[DAT+cursorY]
		cmp al,[DAT+heightCh]
		jc NewLine0

		mov al,[DAT+heightCh]	; не обязательно, но всё таки
		dec al
		mov [DAT+cursorY],al

		call ScrollUp
		mov al,[DAT+cursorY]

NewLine0:	inc al
		mov [DAT+cursorY],al
		mov [DAT+cursorX],BYTE 0
		ret

;---------------------------------------------------------------------------------------

CursorBack:	mov al,[DAT+cursorX]
		and al,al
		jz CursorBack0

		dec al
		jmp CursorBack1

CursorBack0:	mov al,[DAT+cursorY]
		and al,al
		jz CursorBack2

		dec al
		mov [DAT+cursorY],al
		mov al,[DAT+widthCh]
		dec al

CursorBack1:	mov [DAT+cursorX],al
CursorBack2:	ret

;---------------------------------------------------------------------------------------

Clear:		movzx eax,BYTE [DAT+heightCh]
		mul BYTE [DAT+widthCh]
		mov ecx,eax

		push ecx
		mov edi,DAT+textBuf
		xor al,al
		rep stosb
		pop ecx

		mov edi,DAT+clrBuf
		mov al,[DAT+textColor]
		rep stosb
		ret

;---------------------------------------------------------------------------------------
;;;; IN: AL = symbol to print in text buffer

PrintSym:	mov cl,al

		mov al,[DAT+cursorY]
		cmp al,[DAT+heightCh]
		jc PrintSym0

		mov al,[DAT+heightCh]	; не обязательно, но всё таки
		dec al
		mov [DAT+cursorY],al

		push cx
		call ScrollUp
		pop cx

PrintSym0:	movzx eax,BYTE [DAT+cursorY]
		mul BYTE [DAT+widthCh]
		add eax,DAT+textBuf
		movzx edi,BYTE [DAT+cursorX]
		add edi,eax

		mov [edi],cl
		mov al,[DAT+textColor]
		mov [edi+clrBuf-textBuf],al

		mov al,[DAT+cursorX]
		inc al
		cmp al,[DAT+widthCh]
		jc PrintSym1

		inc BYTE [DAT+cursorY]
		xor al,al

PrintSym1:	mov [DAT+cursorX],al
		ret

;---------------------------------------------------------------------------------------

ScrollUp:	mov edi,DAT+textBuf
		mov esi,edi
		movzx eax,BYTE [DAT+widthCh]
		add esi,eax

		movzx eax,BYTE [DAT+heightCh]
		dec eax
		mul BYTE [DAT+widthCh]
		mov ecx,eax

		push ecx,esi,edi

		rep movsb

		mov esi,edi
		inc edi
		mov [esi],BYTE 0
		movzx ecx,BYTE [DAT+widthCh]
		dec ecx
		rep movsb

		pop edi,esi,ecx

		add esi,clrBuf-textBuf
		add edi,clrBuf-textBuf

		rep movsb

		mov esi,edi
		inc edi
		mov al,[DAT+textColor]
		mov [esi],al
		movzx ecx,BYTE [DAT+widthCh]
		dec ecx
		rep movsb

		ret

;---------------------------------------------------------------------------------------

Init:		mov ax,200
		div BYTE [font+8]
		cmp al,51
		jc Init0
		mov al,50
Init0:		mov [DAT+heightCh],al

		mov ax,320
		div BYTE [font+9]
		cmp al,101
		jc Init1
		mov al,100
Init1:		mov [DAT+widthCh],al

		mov ax,320
		movzx bx,BYTE [font+9]
		sub ax,bx
		mov [DAT+prChAdd],ax

		mov [DAT+textColor],BYTE 15
		mov [DAT+backColor],BYTE 0
		mov [DAT+cursorColor],BYTE 5+1
		mov [DAT+cursorX],BYTE 0
		mov [DAT+cursorY],BYTE 0
		mov [DAT+tabSize],BYTE 8

		jmp Clear
;---------------------------------------------------------------------------------------

PrintTextBuf:	call ClearScr
		call PrintCursor

		mov esi,DAT+textBuf
		xor bh,bh
		mov ch,[DAT+heightCh]

PrintTextBuf0:	xor bl,bl
		mov cl,[DAT+widthCh]

PrintTextBuf1:	mov dl,[esi+clrBuf-textBuf]
		lodsb
		push esi,bx,cx
		call PrintCharScr
		pop cx,bx,esi
		inc bl
		dec cl
		jnz PrintTextBuf1

		inc bh
		dec ch
		jnz PrintTextBuf0
		ret

;---------------------------------------------------------------------------------------

InitPalette:	mov ecx,0x100
		mov esi,DAT+palette
		mov dx,0x3C8
		xor ah,ah

InitPalette0:	mov al,ah
		out dx,al

		inc dx
		lodsb
		shr al,2
		out dx,al
		lodsb
		shr al,2
		out dx,al
		lodsb
		shr al,2
		out dx,al
		dec dx

		inc ah
		loop InitPalette0
		ret

;---------------------------------------------------------------------------------------

ClearScr:	cmp BYTE [DAT+backImg], 0
		jz ClearScr0		

		mov esi,DAT+picBuf
		mov edi,DAT+scrBuf
		mov ecx,320*200/4
		rep movsd
		ret

ClearScr0:	mov al,[DAT+backColor]
		mov ah,al
		mov bx,ax
		shl eax,0x10
		mov ax,bx

		mov edi,DAT+scrBuf
		mov ecx,320*200/4
		rep stosd
		ret

;---------------------------------------------------------------------------------------

PrintCursor:	movzx eax,BYTE [DAT+cursorY]
		cmp al,[DAT+heightCh]
		jnc PrintCursor1

		mul BYTE [font+8]
		imul eax,320
		mov ecx,eax

		movzx eax,BYTE [DAT+cursorX]
		mul BYTE [font+9]
		add eax,ecx

		add eax,DAT+scrBuf
		mov edi,eax

		mov bl,[font+8]
		mov bh,[DAT+textColor]
		movzx edx,WORD [DAT+prChAdd]
		mov al,[DAT+cursorColor]

PrintCursor0:	movzx ecx,BYTE [font+9]
		rep stosb
		add edi,edx
		dec bl
		jnz PrintCursor0

PrintCursor1:	ret

;---------------------------------------------------------------------------------------
;;;; IN: AL = char, BL = x, BH = y, DL = color

PrintCharScr:	mov [DAT+PrintCharScr_clr],dl
		movzx ecx,BYTE [font+8]

		movzx eax,al
		mul cx
		add eax,font+10
		mov esi,eax

		movzx eax,bh
		mul cx
		imul eax,320
		mov ecx,eax

		movzx eax,bl
		mul BYTE [font+9]
		add eax,ecx

		add eax,DAT+scrBuf
		mov edi,eax

		mov bl,[font+8]
		mov bh,[DAT+PrintCharScr_clr]
		movzx edx,WORD [DAT+prChAdd]

PrintCharScr0:	lodsb
		movzx ecx,BYTE [font+9]

PrintCharScr1:	shl al,1
		jnc PrintCharScr2
		mov [edi],bh
PrintCharScr2:	inc edi
		loop PrintCharScr1

		add edi,edx
		dec bl
		jnz PrintCharScr0
		ret

;---------------------------------------------------------------------------------------

BlitScreen:	mov esi,DAT+scrBuf
		mov ecx,320*200/4
		mov edi,0xA0000

BlitScreen0:	lodsd
		mov [gs:edi],eax
		add edi,4
		loop BlitScreen0
		ret

;---------------------------------------------------------------------------------------

font:		incbin "fonts/normal1_4x8.font"

;---------------------------------------------------------------------------------------

DAT:		struc _DATA
PrintCharScr_clr:
		resb 1

numPrintBuf:	resb 10
putZero0:	resb 1

prChAdd:	resw 1
showCursor:	resb 1
cursorX:	resb 1
cursorY:	resb 1
cursorColor:	resb 1
backColor:	resb 1
textColor:	resb 1
widthCh:	resb 1
heightCh:	resb 1
tabSize:	resb 1
backImg:	resb 1		; 0 - no, 1 - yes

msgBuf:		resb 0x10000
msgBufE:

textBuf:	resb 100*50
clrBuf:		resb 100*50
scrBuf:		resb 320*200
palette:	resb 0x100*3
picBuf:		resb 320*200
_DATA_LEN:
		endstruc
