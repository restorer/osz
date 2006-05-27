%define dev_Open		0
%define dev_Close		1
%define dev_ReadSector		2

;--------------------------------------------------------------------------------------------

		struc sdev_ReadSector
.deviceID:	resd 1
.sectorL: 	resd 1
.sectorH:	resd 1
.msize:
		endstruc

;--------------------------------------------------------------------------------------------

		struc sdev_Close
.deviceID:	resd 1
.msize:
		endstruc
