main.bin: main.s
	nasm -f bin main.s -o main.bin

run: main.bin
	qemu-system-x86_64 -drive format=raw,file=main.bin

clean:
	rm -f main.bin