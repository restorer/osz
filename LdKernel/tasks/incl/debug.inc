;--------------------------------------------------------------------------------------------

__dbg_console_name	db "console.library"
__dbg_console_len	equ $-__dbg_console_name
__dbg_msg		times 5 db 0

__dbg_PrintNum:		push eax,ebx,ecx,edx,esi,edi

			mov esi,__dbg_console_name
			mov ecx,__dbg_console_len
			xor ebx,ebx
			xor edx,edx
			mov eax,msg_FindTaskByName
			int i_SendMessageW
			push eax

			mov ebx,eax
			mov eax,cons_PrintNumber
			mov esi,__dbg_msg
			mov ecx,5
			xor edx,edx
			int i_SendMessageW

			mov [__dbg_msg],BYTE 0x0D
			pop ebx
			mov eax,cons_PrintChar
			mov esi,__dbg_msg
			mov ecx,1
			xor edx,edx
			int i_SendMessageW

			pop edi,esi,edx,ecx,ebx,eax
			ret

__dbg_PrintNumS:	push eax,ebx,ecx,edx,esi,edi

			mov esi,__dbg_console_name
			mov ecx,__dbg_console_len
			xor ebx,ebx
			xor edx,edx
			mov eax,msg_FindTaskByName
			int i_SendMessageW
			push eax

			mov ebx,eax
			mov eax,cons_PrintNumber
			mov esi,__dbg_msg
			mov ecx,5
			xor edx,edx
			int i_SendMessageW

			mov [__dbg_msg],BYTE " "
			pop ebx
			mov eax,cons_PrintChar
			mov esi,__dbg_msg
			mov ecx,1
			xor edx,edx
			int i_SendMessageW

			pop edi,esi,edx,ecx,ebx,eax
			ret

__dbg_PrintStr:		push eax,ebx,ecx,edx,esi,edi
			push ecx,esi

			mov esi,__dbg_console_name
			mov ecx,__dbg_console_len
			xor ebx,ebx
			xor edx,edx
			mov eax,msg_FindTaskByName
			int i_SendMessageW

			pop esi,ecx
			push eax

			mov ebx,eax
			mov eax,cons_PrintString
			xor edx,edx
			int i_SendMessageW

			mov [__dbg_msg],BYTE 0x0D
			pop ebx
			mov eax,cons_PrintChar
			mov esi,__dbg_msg
			mov ecx,1
			xor edx,edx
			int i_SendMessageW

			pop edi,esi,edx,ecx,ebx,eax
			ret

__dbg_PrintStrS:	push eax,ebx,ecx,edx,esi,edi
			push ecx,esi

			mov esi,__dbg_console_name
			mov ecx,__dbg_console_len
			xor ebx,ebx
			xor edx,edx
			mov eax,msg_FindTaskByName
			int i_SendMessageW

			pop esi,ecx
			push eax

			mov ebx,eax
			mov eax,cons_PrintString
			xor edx,edx
			int i_SendMessageW

			mov [__dbg_msg],BYTE " "
			pop ebx
			mov eax,cons_PrintChar
			mov esi,__dbg_msg
			mov ecx,1
			xor edx,edx
			int i_SendMessageW

			pop edi,esi,edx,ecx,ebx,eax
			ret

;--------------------------------------------------------------------------------------------
