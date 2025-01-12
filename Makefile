run: os-image
	qemu-system-x86_64 -fda $<

os-image: boot.bin kernel.bin
	cat $^ > $@ && mv *.o *.bin build/

kernel.bin: kernel_entry.o kernel.o
	ld -m elf_i386 -o $@ -Ttext 0x1000 $^ --oformat binary

kernel.o: kernel.c
	gcc -m32 -fno-pie -ffreestanding -c $< -o $@ 

kernel_entry.o: kernel_entry.asm
	nasm $< -f elf -o $@

boot.bin: boot32.asm
	nasm $< -f bin -o $@

clean:
	rm *.o *.bin os-image