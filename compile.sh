#!/bin/sh

cd LdKernel
./compile.sh
cd ..

MakeZImg/makezimg b BootLoader/boot.bin osz.img
MakeZImg/makezimg a LdKernel/ldkernel LDKERNEL osz.img
MakeZImg/makezimg a Test/test.txt TEST.TXT osz.img
MakeZImg/makezimg a LdKernel/tasks/bin/shell.bin SHELL osz.img

MakeZImg/makezimg a LdKernel/tasks/bin/test1.bin TEST1 osz.img
MakeZImg/makezimg a LdKernel/tasks/bin/test2.bin TEST2 osz.img
MakeZImg/makezimg a LdKernel/tasks/bin/test3.bin TEST3 osz.img
MakeZImg/makezimg a LdKernel/tasks/bin/test4.bin TEST4 osz.img
MakeZImg/makezimg a LdKernel/tasks/bin/test5.bin TEST5 osz.img

MakeZImg/makezimg a LdKernel/tasks/bin/testd.bin TESTD osz.img
