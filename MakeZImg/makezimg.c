#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifndef MAX_PATH
#define MAX_PATH 4096
#endif

typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef unsigned long DWORD;

#define IMG_SIZE 1474560

BYTE img[IMG_SIZE];
BYTE secBuf[512];

void StrikeError(char *message)
{
	printf("Error: %s\n", message);
	exit(0);
}

void ReadImage(char *imgName)
{
	FILE *fp;
	if ((fp = fopen(imgName, "rb")) == NULL) StrikeError("Can't read image file");
	fread(img, 1, IMG_SIZE, fp);
	fclose(fp);
}

void WriteImage(char *imgName)
{
	FILE *fp;
	if ((fp = fopen(imgName, "wb")) == NULL) StrikeError("Can't write image file");
	fwrite(img, 1, IMG_SIZE, fp);
	fclose(fp);
}

void PutBYTE(int addr, BYTE val)
{
	if (addr<0 || addr>=IMG_SIZE) return;
	img[addr] = val;
}

void PutWORD(int addr, WORD val)
{
	if (addr<0 || (addr+1)>=IMG_SIZE) return;
	img[addr] = (BYTE)(val & 0x00FF);
	img[addr+1] = (BYTE)(val >> 8);
}

void PutDWORD(int addr, DWORD val)
{
	if (addr<0 || (addr+3)>=IMG_SIZE) return;
	img[addr] = (BYTE)(val & 0x000000FF);
	img[addr+1] = (BYTE)((val & 0x0000FF00) >> 8);
	img[addr+2] = (BYTE)((val & 0x00FF0000) >> 16);
	img[addr+3] = (BYTE)(val >> 24);
}

BYTE GetBYTE(int addr)
{
	if (addr<0 || addr>=IMG_SIZE) return 0;
	return img[addr];
}

WORD GetWORD(int addr)
{
	if (addr<0 || (addr+1)>=IMG_SIZE) return 0;
	return ((WORD)img[addr] | (((WORD)img[addr+1])<<8));
}

DWORD GetDWORD(int addr)
{
	if (addr<0 || (addr+1)>=IMG_SIZE) return 0;
	return ((DWORD)img[addr] |
		(((DWORD)img[addr+1])<<8) |
		(((DWORD)img[addr+2])<<16) |
		(((DWORD)img[addr+3])<<24));
}

void ZeroImage(void)
{
	memset(img, 0, IMG_SIZE);
}

void ReadBootSec(char *bsecName)
{
	FILE *fp;
	if ((fp = fopen(bsecName, "rb")) == NULL) StrikeError("Can't read boot sector file");
	fread(img, 1, 512, fp);
	fclose(fp);
}

void PutString(int addr, char *str)
{
	int i;
	for (i = 0; i < strlen(str); i++) PutBYTE(addr+i, str[i]);
}

void PutFatEl(int fatAddr, int num, int val)
{
	int addr;
	addr = fatAddr + num * 3 / 2;
	if (num & 1) PutWORD(addr, (GetWORD(addr) & 0x000F) | (val << 4));
	else PutWORD(addr, (GetWORD(addr) & 0xF000) | val);
}

int GetFatEl(int fatAddr, int num)
{
	int addr;
	addr = fatAddr + num * 3 / 2;
	if (num & 1) return (GetWORD(addr) >> 4);
	else return (GetWORD(addr) & 0x0FFF);
}

void InitImage(char *bsecName, char *imgName)
{
	int bps, eoc;
	int fatStart, fat2Start, rootStart, secPerRoot, dataStart;
	int fatAddr;

	printf("Initializing image ...\n");

	ZeroImage();
	ReadBootSec(bsecName);

	PutString(0x03, "ProZroks");	// BS_OEMName
	PutWORD(0x0B, 512);		// BPB_BytesPerSec
	PutBYTE(0x0D, 1);		// BPB_SecPerClust
	PutWORD(0x0E, 1);		// BPB_RsvdSecCnt
	PutBYTE(0x10, 2);		// BPB_NumFATs
	PutWORD(0x11, 0xE0);		// BPB_RootEntCnt
	PutWORD(0x13, 0x0B40);		// BPB_TotSec16
	PutBYTE(0x15, 0xF0);		// BPB_Media
	PutWORD(0x16, 9);		// BPB_FATSz16
	PutWORD(0x18, 18);		// BPB_SecPerTrk
	PutWORD(0x1A, 2);		// BPB_NumHeads
	PutDWORD(0x1C, 0);		// BPB_HiddSec
	PutDWORD(0x20, 0);		// BPB_TotSec32
	PutBYTE(0x24, 0);		// BS_DrvNum
	PutBYTE(0x25, 0);		// BS_Reserved1
	PutBYTE(0x26, 0x29);		// BS_BootSig
	PutDWORD(0x27, 0x00162244);	// BS_VolID
	PutString(0x2B, "OsZ Disk   ");	// BS_VolLab
	PutString(0x36, "FAT12   ");	// BS_FilSysType
	PutWORD(0x01FE, 0xAA55);

	bps = GetWORD(0x0B);	// bytesPerSec
	eoc = 0xFFF;		// end of clusterchain

	// fatStart = hiddenSectors + resSectors
	fatStart = GetDWORD(0x1C) + GetWORD(0x0E);
	// fat2Start = fatStart + secPerFat
	fat2Start = fatStart + (int)GetWORD(0x16);
	// rootStart = fatCopies * sectPerFat + fatStart
	rootStart = (int)GetBYTE(0x10) * (int)GetWORD(0x16) + fatStart;
	// secPerRoot = rootEntCnt * 32 / bytesPerSec
	secPerRoot = (int)GetWORD(0x11) * 32 / bps;
	// dataStart = rootStart + secPerRoot
	dataStart = rootStart + secPerRoot;

	printf("DGB: rootStart=0x%04X, secPerRoot=0x%04X, dataStart=0x%04X\n", rootStart, secPerRoot, dataStart);

	fatAddr = fatStart * bps;

	PutFatEl(fatAddr, 0, 0xFF8);
	PutFatEl(fatAddr, 1, eoc);

	WriteImage(imgName);
}

void ImageInfo(char *imgName)
{
	int i;
	int bps, eoc;
	int fatStart, fat2Start, rootStart, secPerRoot, dataStart;
	int fatAddr;

	printf("Image Info...\n");

	ReadImage(imgName);

	bps = GetWORD(0x0B);	// bytesPerSec
	eoc = 0xFFF;		// end of clusterchain

	// fatStart = hiddenSectors + resSectors
	fatStart = GetDWORD(0x1C) + GetWORD(0x0E);
	// fat2Start = fatStart + secPerFat
	fat2Start = fatStart + (int)GetWORD(0x16);
	// rootStart = fatCopies * sectPerFat + fatStart
	rootStart = (int)GetBYTE(0x10) * (int)GetWORD(0x16) + fatStart;
	// secPerRoot = rootEntCnt * 32 / bytesPerSec
	secPerRoot = (int)GetWORD(0x11) * 32 / bps;
	// dataStart = rootStart + secPerRoot
	dataStart = rootStart + secPerRoot;

	fatAddr = fatStart * bps;

	for (i = 0; i < 64; i++) {
		if (i) printf(" ");
		printf("%03X", GetFatEl(fatAddr, i));
	}

	printf("\n");
}

void RemoveFile(char *fName, char *imgName)
{
	printf("Removing file ...");
	StrikeError("Not implemented yet");
}

long GetFileSize(char *fName)
{
	FILE *fp;
	long fsize;
	if ((fp = fopen(fName, "rb")) == NULL) StrikeError("Error opening file");
	fseek(fp, 0, SEEK_END);
	fsize = ftell(fp);
	fclose(fp);
	return fsize;
}

int GetFreeFatEl(int fatAddr, int clustCnt)
{
	int i;
	for (i = 2; i < clustCnt; i++) {
		if (GetFatEl(fatAddr, i) == 0) return i;
	}
	return -1;
}

WORD GetTime(struct tm *tme)
{
	return ((tme->tm_hour << 11) |
		(tme->tm_min << 5) |
		(tme->tm_sec / 2));
}

WORD GetDate(struct tm *tme)
{
	return (((tme->tm_year - 80) << 9) |
		(tme->tm_mon << 5) |
		tme->tm_mday);
}

int FindFile(int rootAddr, int rootEnt, BYTE *fName)
{
	int i, j, addr;

	for (i=0, addr=rootAddr; i < rootEnt; i++, addr+=32)
	{
		for (j = 0; j < 11; j++) {
			if (GetBYTE(addr+j) != fName[j]) break;
		}
		if (j >= 11) return i;
	}

	return -1;
}

void WriteBufToCluster(int dataAddr, int clustSize, int clust)
{
	int i, addr;
	addr = dataAddr + (clust-2) * clustSize;
	for (i = 0; i < sizeof(secBuf); i++) PutBYTE(addr + i, secBuf[i]);
}

void CopyFat(int fat1, int fat2, int cnt)
{
	int i;
	for (i = 0; i < cnt; i++) PutFatEl(fat2, i, GetFatEl(fat1, i));
}

void AddFile(char *fName, char *fiName, char *imgName)
{
	int i, j, ex, addr, fsize, clust, sz, nclust;
	int bps, eoc, rootEnt, fatEnt, clustCnt;
	int fatStart, fat2Start, rootStart, secPerRoot, dataStart;
	int fatAddr, rootAddr, sectPerClust;
	BYTE resName[11];
	struct tm *tme;
	time_t tmt;
	FILE *fp;

	printf("Adding file ...");
	fsize = GetFileSize(fName);

	ReadImage(imgName);
	bps = GetWORD(0x0B);
	eoc = 0xFFF;
	sectPerClust = GetBYTE(0x0D);

	if (sectPerClust != 1) StrikeError("Internal error: AddFile works correct only in sectPerCluster==1");

	// clustCnt = totalSectors / sectPerCluster
	clustCnt = (int)GetWORD(0x13) / sectPerClust;
	rootEnt = GetWORD(0x11);
	fatStart = GetDWORD(0x1C) + GetWORD(0x0E);
	fat2Start = fatStart + (int)GetWORD(0x16);
	rootStart = (int)GetBYTE(0x10) * (int)GetWORD(0x16) + fatStart;
	secPerRoot = rootEnt * 32 / bps;
	dataStart = rootStart + secPerRoot;
	fatAddr = fatStart * bps;
	rootAddr = rootStart * bps;

	printf("DBG: rootAddr=0x%04X\n", rootAddr);

	for (i=0, j=0, ex=0; i<strlen(fiName) && j<12; i++, j++)
	{
		if (fiName[i] == '.')
		{
			if (ex) StrikeError("Multiple extensions not allowed");
			for (; j < 8; j++) resName[j] = ' ';
			j--;
			ex = 1;
		}
		else
		{
			if (j>=8 && !ex)
			{
				for (; i<strlen(fiName) && fiName[i]!='.'; i++);
				continue;
			}
			resName[j] = toupper(fiName[i]);
		}
	}

	for (; j < 12; j++) resName[j] = ' ';

	if (FindFile(rootAddr, rootEnt, resName) >= 0) StrikeError("File already exists");

	for (i=0, addr=rootAddr; i < rootEnt; i++, addr+=32) {
		if (GetBYTE(addr)==0x00 || GetBYTE(addr)==0xE5) break;
	}
	if (i >= rootEnt) StrikeError("No free root entries");

	clust = GetFreeFatEl(fatAddr, clustCnt);
	if (clust < 0) StrikeError("No free FAT entry");

	tmt = time(NULL);
	tme = localtime(&tmt);

	memcpy(&img[addr], resName, 11);	// DIR_Name			[ +0 ]
	addr += 11;
	PutBYTE(addr++, 0);			// DIR_Attr			[ +11 ]
	PutBYTE(addr++, 0);			// DIR_NTRes			[ +12 ]
	PutBYTE(addr++, 0);			// DIR_CrtTimeTenth (FAT32)	[ +13 ]
	PutWORD(addr, 0);			// DIR_CrtTime (FAT32)		[ +14 ]
	addr += 2;
	PutWORD(addr, 0);			// DIR_CrtDate (FAT32)		[ +16 ]
	addr += 2;
	PutWORD(addr, 0);			// DIR_LstAccDate (FAT32)	[ +18 ]
	addr += 2;
	PutWORD(addr, 0);			// DIR_FstClasHl (FAT32)	[ +20 ]
	addr += 2;
	PutWORD(addr, GetTime(tme));		// DIR_WrtTime			[ +22 ]
	addr += 2;
	PutWORD(addr, GetDate(tme));		// DIR_WrtDate			[ +24 ]
	addr += 2;
	PutWORD(addr, clust);			// DIR_FstClusLo		[ +26 ]
	addr += 2;
	PutDWORD(addr, fsize);			// DIR_FileSize			[ +28 ]

	if ((fp = fopen(fName, "rb")) == NULL) StrikeError("Error reading file");
	sz = fsize;

	do
	{
		sz -= fread(secBuf, 1, sectPerClust*bps, fp);
		WriteBufToCluster(dataStart*bps, sectPerClust*bps, clust);
		if (sz) {
			PutFatEl(fatAddr, clust, eoc);	// temporary, couse if not set it here, GetFreeFatEl gets this element
			nclust = GetFreeFatEl(fatAddr, clustCnt);
			if (nclust < 0) StrikeError("No free FAT entries to store file");
			PutFatEl(fatAddr, clust, nclust);
			clust = nclust;
		} else PutFatEl(fatAddr, clust, eoc);
	} while (sz);

	fclose(fp);

	CopyFat(fatAddr, fat2Start*bps, clustCnt);
	WriteImage(imgName);
}

int main(char argc, char *argv[])
{
	printf("MakeZImg (c)Restorer,2006\n");

	if (argc < 2)
	{
		printf("Usage: 'makezimg b bootsec.bin osz.img' init image\n");
		printf("       'makezimg a filename IMAGE.NME osz.img' add file to image\n");
		printf("       'makezimg r filename osz.img' remove file from image\n");
		printf("       'makezimg i osz.img' image info\n");
	}

	if (!strcmp(argv[1], "b")) InitImage(argv[2], argv[3]);
	else
	if (!strcmp(argv[1], "a")) AddFile(argv[2], argv[3], argv[4]);
	else
	if (!strcmp(argv[1], "r")) RemoveFile(argv[2], argv[3]);
	else
	if (!strcmp(argv[1], "i")) ImageInfo(argv[2]);
	else StrikeError("Incorrect parameters");

	printf("... Success\n");
	return 0;
}
