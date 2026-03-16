# hexdump -C -n 32 kernel.bin
# x/32xb 0x0

CFLAGS += -m64
CFLAGS += -mno-red-zone
CFLAGS += -nostdlib
CFLAGS += -nodefaultlibs
CFLAGS += -ffreestanding
CFLAGS += -fno-stack-protector
CFLAGS += -fno-pic
CFLAGS += -ffunction-sections
CFLAGS += -Wall
CFLAGS += -Wextra

LFLAGS += -melf_x86_64
LFLAGS += -nostdlib

GDBFLAGS += --eval-command="set auto-load safe-path ."
GDBFLAGS += --eval-command="set confirm off"
GDBFLAGS += --eval-command="set listsize 30"
GDBFLAGS += --eval-command="set print pretty on"
GDBFLAGS += --eval-command="set print array on"
GDBFLAGS += --eval-command="set disassembly-flavor intel"
# GDBFLAGS += --eval-command="set architecture i8086"
# GDBFLAGS += --eval-command="set architecture i386"
# GDBFLAGS += --eval-command="set architecture i386:x86-64"
GDBFLAGS += --eval-command="target extended-remote localhost:9001"
GDBFLAGS += --eval-command="add-symbol-file stage1/stage1.elf 0x7C00"
GDBFLAGS += --eval-command="add-symbol-file stage2/stage2.elf 0x8000"
GDBFLAGS += --eval-command="add-symbol-file kernel/kernel.elf 0x100000"
GDBFLAGS += --eval-command="break *0x7C00"
GDBFLAGS += --eval-command="break *0x8000"
GDBFLAGS += --eval-command="break *0x100000"
GDBFLAGS += --eval-command="continue"

KERNEL_OBJS += $(patsubst kernel/%.s, kernel/%.o, $(wildcard kernel/*.s))
KERNEL_OBJS += $(patsubst kernel/%.c, kernel/%.o, $(wildcard kernel/*.c))

kernel/%.o: kernel/%.s
	nasm -f elf64 -g -F dwarf $< -o $@

kernel/%.o: kernel/%.c
	gcc $(KERNEL_CFLAGS) -c $< -o $@

all: stage1 stage2 kernel disk

stage1:
	nasm stage1/stage1.s -f elf64 -g -F dwarf -o stage1/stage1.o
	ld $(LFLAGS) -T stage1/linker.ld -Map=stage1/stage1.map stage1/stage1.o -o stage1/stage1.elf
	objcopy -O binary stage1/stage1.elf stage1/stage1.bin

stage2:
	nasm stage2/stage2.s -f elf64 -g -F dwarf -o stage2/stage2.o
	ld $(LFLAGS) -T stage2/linker.ld -Map=stage2/stage2.map stage2/stage2.o -o stage2/stage2.elf
	objcopy -O binary stage2/stage2.elf stage2/stage2.bin

kernel: $(KERNEL_OBJS)
	ld $(LFLAGS) -T kernel/linker.ld -Map=kernel/kernel.map $(KERNEL_OBJS) -o kernel/kernel.elf
	objcopy -O binary kernel/kernel.elf kernel/kernel.bin

disk:
	dd if=/dev/zero of=disk.img bs=512 count=4096
	dd if=stage1/stage1.bin of=disk.img conv=notrunc seek=0
	dd if=stage2/stage2.bin of=disk.img conv=notrunc seek=1
	dd if=kernel/kernel.bin of=disk.img conv=notrunc seek=33

system:
	qemu-system-x86_64 \
		-drive format=raw,file=disk.img \
		-m 1G \
		-d int \
		-no-reboot \
		-no-shutdown &

dsystem:
	qemu-system-x86_64 \
		-drive format=raw,file=disk.img \
		-m 1G \
		-d int \
		-no-reboot \
		-no-shutdown \
		-gdb tcp:0.0.0.0:9001 \
		-S &

debug:
	gdb -q $(GDBFLAGS)

clean:
	rm -f stage1/*.o stage1/*.map stage1/*.elf stage1/*.bin
	rm -f stage2/*.o stage2/*.map stage2/*.elf stage2/*.bin
	rm -f kernel/*.o kernel/*.map kernel/*.elf kernel/*.bin
	rm -f *.img

.PHONY: stage1 stage2 kernel disk system dsystem debug clean