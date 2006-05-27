#!/bin/sh

cd tasks
./compile.sh
cd ..
nasm -f bin ldkernel.asm -o ldkernel
