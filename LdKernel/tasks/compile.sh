nasm -f bin exec_library.asm -o bin/exec_library.bin
nasm -f bin floppy_device.asm -o bin/floppy_device.bin
nasm -f bin fat12_handler.asm -o bin/fat12_handler.bin
nasm -f bin shell.asm -o bin/shell.bin
nasm -f bin console_library.asm -o bin/console_library.bin
nasm -f bin keyboard_handler.asm -o bin/keyboard_handler.bin
nasm -f bin init.asm -o bin/init.bin

nasm -f bin test1_t.asm -o bin/test1_t.bin
nasm -f bin test1.asm -o bin/test1.bin
nasm -f bin test2.asm -o bin/test2.bin
nasm -f bin test3.asm -o bin/test3.bin
nasm -f bin test4.asm -o bin/test4.bin
nasm -f bin test5.asm -o bin/test5.bin

nasm -f bin testd_t.asm -o bin/testd_t.bin
nasm -f bin testd.asm -o bin/testd.bin
