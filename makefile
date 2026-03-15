
ArcOS.bin: boot.bin kernel.bin
	cat boot.bin kernel.bin > ArcOS.bin

boot.bin: boot.s
	nasm -f bin boot.s -o boot.bin

kernel.bin: main.s
	nasm -f bin main.s -o kernel.bin

run: ArcOS.bin
	qemu-system-x86_64 -drive file=ArcOS.bin,format=raw,if=floppy

clean:
	rm -f boot.bin kernel.bin ArcOS.bin
