;-------------------------------------------------------------------------------
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
;;;; IN: ESI - string, EDI - screenPtr, AH - attribute
;;;; OUT: text on screen
;;;; MODIFY: ESI, EDI, AL

PrintText:	lodsb
		and al,al
		jz PrintText0

		stosb
		mov al,ah
		stosb
		jmp short PrintText

PrintText0:	ret

;-------------------------------------------------------------------------------
;;;;

kprhexPos	dd 0xB8000
kprhexColor	db 15

kprhexbufD	db "...."
kprhexbufW	db ".."
kprhexbufB	db ".."
		db 0

PrintHexDwordScreen:
		pushad
		mov edi,kprhexbufD
		call PrintHexDword
		mov esi,kprhexbufD

PrintHexOnScreen:
		mov ah,[kprhexColor]
		mov edi,[kprhexPos]
		call PrintText
		mov edi,[kprhexPos]
		add edi,160
		mov [kprhexPos],edi
		popad
		ret

PrintHexWordScreen:
		pushad
		mov edi,kprhexbufW
		call PrintHexWord
		mov esi,kprhexbufW
		jmp PrintHexOnScreen

PrintHexByteScreen:
		pushad
		mov edi,kprhexbufB
		call PrintHexByte
		mov esi,kprhexbufB
		jmp PrintHexOnScreen
