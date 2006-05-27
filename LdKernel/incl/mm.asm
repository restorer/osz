;-----------------------------------------------------------------------------------
;;;; IN: memMap
;;;; OUT: if (FLAG_C) error(); else {modify_memMap; EAX=Address;}
;;;; MODIFY: EAX (что собственно говоря логично ;), ECX, EDX, ESI

AllocPage:	mov esi,memMap
		mov ecx,0x20000/4+1	; +1 из-за логики работы loopz

AllocPage_:	xor edx,edx
		dec edx

AllocPage0:	lodsd
		cmp eax,edx
		loopz AllocPage0
		jecxz AllocPage3

		sub esi,4
		xor edx,edx
		mov ecx,$80000000

AllocPage1:	rol ecx,1
		shr eax,1
		jnc AllocPage2
		inc dl
		jmp short AllocPage1

AllocPage2:	or [esi],ecx

		mov eax,esi
		sub eax,memMap	; EAX = align(Address, 32) / 4096 / 8
		shl eax,3	; EAX = align(Address, 32) / 4096
		add eax,edx	; EAX = Address / 4096
		shl eax,12	; EAX = Address
		clc
		ret

AllocPage3:	stc
		ret

;-----------------------------------------------------------------------------------
;;;; IN: EAX = Address, memMap
;;;; OUT: memMap modifed
;;;; MODIFY: EAX, CL, ESI

FreePage:	shr eax,12	; EAX = Address / 4096 = PageNum
		mov cl,al
		and cl,7

		shr eax,3
		add eax,memMap
		mov esi,eax

		mov al,11111110b
		rol al,cl
		and [esi],al
		ret

;-----------------------------------------------------------------------------------
;;;; IN: EAX = Address, memMap
;;;; OUT: memMap modifed
;;;; MODIFY: EAX, CL, ESI

ReservePage:
		shr eax,12	; EAX = Address / 4096 = PageNum
		mov cl,al
		and cl,7

		shr eax,3
		add eax,memMap
		mov esi,eax

		mov al,00000001b
		rol al,cl
		or [esi],al
		ret

;-------------------------------------------------------------------------------
;;;; IN: EAX = size
;;;; OUT: ECX = pages
;;;; MODIFY: EAX

SizeToPages:	test eax,0x0FFF
		jz SizeToPages0		; рулез! размерчик уже за-align-ен под размер страницы
		add eax,0x1000		; иначе докинем лишнюю
SizeToPages0:	shr eax,12
		mov ecx,eax
		ret

;-------------------------------------------------------------------------------
;;;; IN: ECX = pages_to_allocate
;;;; OUT: EAX = base_address
;;;; MODIFY:

; выделяет pages_to_allocate подряд идущих страниц страниц
; надо будет это заоптимизить (по крайней мере достаточно несложно ускорить это в 32 раза)

AllocPages11:	stc
		ret

AllocPages:	mov [allocPagesNeed],ecx
		mov esi,memMap
		mov ecx,0x20000/4+1	; +1 из-за логики работы loopz

AllocPages0:	xor edx,edx		; пытаемся найти свободную страницу
		dec edx

AllocPages1:	lodsd
		cmp eax,edx
		loopz AllocPages1
		jecxz AllocPages11	; печально, нифига не нашли ;_;

		mov edx,esi
		sub edx,4		; адресочек вернем на тот, с которого брали EAX
		mov [allocAddress],edx	; и запомним
		xor edx,edx		; EDX - счетчик свободных страниц

AllocPages2:	push ecx
		mov ecx,32

AllocPages3:	dec ecx
		shr eax,1
		jc AllocPages3		; находим первый свободный бит

AllocPages4:	inc edx
		jecxz AllocPages5	; битики уже закончились
		dec ecx
		shr eax,1
		jnc AllocPages4
		jmp short AllocPages6	; как это не печально, но мы нарвались на занятую page

AllocPages5:    pop ecx
		cmp edx,[allocPagesNeed]
		jnc AllocPages8		; а может уже хватит ?

		jecxz AllocPages7	; упс... закончилось уже вообще все (или нет?)

		lodsd			; следующий DWORD
		cmp eax,0xFFFFFFFF
		jz AllocPages0
		jmp short AllocPages2	; продолжим

AllocPages6:	pop ecx			; снимем балласт со стека

AllocPages7:	cmp edx,[allocPagesNeed]
		jnc AllocPages8
		jmp AllocPages0		; если мы не набрали необходимого кол-ва страниц, то поперли искать снова

AllocPages8:
		mov esi,[allocAddress]	; ой как все заебись!
		mov ecx,2		; тупо, медленно, но верно выделяем память
		call AllocPage_		; используя "недокументированный" вызов AllocPage_
					; она не может "завалиться", т.к. несколько сотен тактов
					; тому назад мы в том месте таки нашли свободную page
		push eax		; сохраним адресок на будующее

		mov ecx,[allocPagesNeed]
		dec ecx
		jz AllocPages10		; неужели надо была только одна страница? (а мы то старались... ^_^)

AllocPages9:	add eax,0x1000
		push eax
		push ecx
		call ReservePage	; ыщо одна тормозная функция
		pop ecx
		pop eax
		loop AllocPages9

AllocPages10:
		pop eax
		clc
		ret

allocPagesNeed	dd 0x12345678
allocAddress	dd 0x12345678

;-------------------------------------------------------------------------------
;;;; IN: EAX = base_address, ECX = pages_count
;;;; OUT:
;;;; MODIFY:

FreePages:	push ecx
		push eax
		call FreePage
		pop eax
		pop ecx
		add eax,0x1000
		loop FreePages
		ret

;-------------------------------------------------------------------------------
;;;; IN: Paging must be disabled
;;;; OUT: [memSizeBl] - mem size in bloks (4kb)
;;;; MODIFY: EAX, EBX, ECX, EDX, ESI

TestMemory:	mov esi,0x100000	; begin from second meg
		xor ebx,ebx
		mov ecx,0x100000 - 0x100	; 4Gb_in_blocks - 1Mb_in_blocks
		mov eax,0x12345678
		mov edx,eax

TestMemory0:	xchg eax,[esi]
		xchg eax,[esi]
		cmp eax,edx
		jnz TestMemory1

		add esi,0x1000	; next 4kb
		inc ebx
		loop TestMemory0

TestMemory1:	inc ebx		; add first meg
		mov [memSizeBl],ebx
		ret
