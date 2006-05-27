%define cons_Clear		0
%define cons_PrintChar		1
%define cons_PrintString	2
%define cons_GetConsoleDim	3
%define cons_ShowCursor		4
%define cous_HideCursor		5
%define cons_SetTextColor	6
%define cons_SetCursorColor	7
%define cons_SetBackColor	8
%define cons_PrintSymbol	9
%define cons_SetCursorCoords	10
%define cons_GetCursorCoords	11
%define cons_PrintNumber	12
%define cons_SetBackImg		13
%define cons_RmBackImg		14

; for cons_SetBackImg :: { palette[0x100][3]; data[320*200]; }, sizeof(msg) = 0xFD00
