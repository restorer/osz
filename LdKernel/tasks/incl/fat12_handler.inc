%define MAX_FILE_NAME		255

%define ehndl_FileNotFound		0xFFFF0000
%define ehndl_NoFreeEntries		0xFFFF0001
%define ehndl_InvalidFileHandler	0xFFFF0002
%define ehndl_InvalidBlockSize		0xFFFF0003

%define hndl_Init		0
%define hndl_Destroy		1
%define hndl_ReadFile		2
%define hndl_GetFileSize	3
%define hndl_Read		4
%define hndl_CloseFile		5

;--------------------------------------------------------------------------------------------

		struc shndl_Init
.devTaskID:	resd 1
.deviceID:	resd 1
.msize:
		endstruc

;--------------------------------------------------------------------------------------------

		struc shndl_FileName
.handlerID	resd 1
.fileName	resb (MAX_FILE_NAME+1)
.msize
		endstruc

;--------------------------------------------------------------------------------------------

		struc shndl_FileHandler
.fileID		resd 1
.msize
		endstruc

;--------------------------------------------------------------------------------------------

		struc shndl_Read
.fileID		resd 1
.blockSize	resd 1
.msize
		endstruc

;--------------------------------------------------------------------------------------------
