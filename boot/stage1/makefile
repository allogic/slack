ASM_FLAGS += -i.
ASM_FLAGS += -f elf64
ASM_FLAGS += -F dwarf
ASM_FLAGS += -g

L_FLAGS += -melf_x86_64
L_FLAGS += -nostdlib
L_FLAGS += -T linker.ld

ASM_SRCS += stage1.s # Must be first to be loaded at 0x7C00

OBJS = $(ASM_SRCS:.s=.o)

%.o: %.s
	nasm $(ASM_FLAGS) $< -o $@

all: $(OBJS)
	ld $(L_FLAGS) -Map=stage1.map $(OBJS) -o stage1.elf
	objcopy -O binary stage1.elf stage1.bin	

clean:
	rm -f *.o *.map *.elf *.bin

.PHONY: all clean