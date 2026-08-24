BUILTIN_PROGS = calc time tzconfig sleep bgconfig
PROGRAMS = $(filter-out $(addprefix progs/,$(addsuffix .bin,$(BUILTIN_PROGS))),$(patsubst progs/%.s,progs/%.bin,$(wildcard progs/*.s)))

ArcOS.bin: boot.bin kernel.bin $(PROGRAMS)
	rm -f ArcOS.img
	dd if=/dev/zero of=ArcOS.img bs=512 count=8192 2>/dev/null
	mkfs.fat -F 16 -s 1 -h 0 -r 224 -S 512 -f 2 -n ARCOS ArcOS.img 2>/dev/null
	mcopy -i ArcOS.img kernel.bin ::KERNEL.BIN
	for f in $(PROGRAMS); do \
		name=$$(basename $$f .bin); \
		mcopy -i ArcOS.img $$f ::$$(echo $$name | tr a-z A-Z).BIN; \
	done
	dd if=boot.bin of=ArcOS.img bs=1 seek=62 count=448 conv=notrunc 2>/dev/null
	mv ArcOS.img ArcOS.bin

boot.bin: boot.s
	nasm -f bin boot.s -o boot.bin

kernel.bin: main.s
	nasm -f bin main.s -o kernel.bin

progs/%.bin: progs/%.s
	nasm -f bin $< -o $@

run: ArcOS.bin
	qemu-system-x86_64 -drive file=ArcOS.bin,format=raw,if=ide

clean:
	rm -f boot.bin kernel.bin ArcOS.bin ArcOS.img progs/*.bin
