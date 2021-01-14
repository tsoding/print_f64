set -xe

nasm -felf64 -F dwarf -g print_f64.asm -o print_f64.o
ld -o print_f64 print_f64.o
