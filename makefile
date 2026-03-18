GDBFLAGS += -ex "set auto-load safe-path ."
GDBFLAGS += -ex "set confirm off"
GDBFLAGS += -ex "set listsize 30"
GDBFLAGS += -ex "set print pretty on"
GDBFLAGS += -ex "set print array on"
GDBFLAGS += -ex "set disassembly-flavor intel"
GDBFLAGS += -ex "target extended-remote localhost:9001"
GDBFLAGS += -ex "add-symbol-file boot/stage1/stage1.elf 0x7C00"
GDBFLAGS += -ex "add-symbol-file boot/stage2/stage2.elf 0x8000"
GDBFLAGS += -ex "add-symbol-file kernel/kernel.elf 0x100000"
GDBFLAGS += -ex "break *0x7C00"
GDBFLAGS += -ex "break *0x8000"
GDBFLAGS += -ex "break *0x100000"
GDBFLAGS += -ex "continue"

all: stage1 stage2 kernel disk

stage1:
	cd boot/stage1 && make

stage2:
	cd boot/stage2 && make

kernel:
	cd kernel && make

disk:
	dd if=/dev/zero of=disk.img bs=512 count=4096
	dd if=boot/stage1/stage1.bin of=disk.img conv=notrunc seek=0
	dd if=boot/stage2/stage2.bin of=disk.img conv=notrunc seek=1
	dd if=kernel/kernel.bin of=disk.img conv=notrunc seek=129

sys:
	qemu-system-x86_64 \
		-drive format=raw,file=disk.img \
		-m 1G \
		-d int \
		-no-reboot \
		-no-shutdown &

dsys:
	qemu-system-x86_64 \
		-drive format=raw,file=disk.img \
		-m 1G \
		-d int \
		-no-reboot \
		-no-shutdown \
		-gdb tcp:0.0.0.0:9001 \
		-S &

dbg:
	gdb -q $(GDBFLAGS)

clean:
	cd boot/stage1 && make clean
	cd boot/stage2 && make clean
	cd kernel && make clean
	rm -f *.img

.PHONY: stage1 stage2 kernel disk sys dsys dbg clean