ASM_FLAGS += -i.
ASM_FLAGS += -f elf64
ASM_FLAGS += -F dwarf
ASM_FLAGS += -g

L_FLAGS += -melf_x86_64
L_FLAGS += -nostdlib
L_FLAGS += -T linker.ld

ASM_SRCS += stage2.s # Must be first to be loaded at 0x8000
ASM_SRCS += gdt.s
ASM_SRCS += ptbl.s
ASM_SRCS += mmap.s

OBJS = $(ASM_SRCS:.s=.o)

%.o: %.s
	nasm $(ASM_FLAGS) $< -o $@

all: $(OBJS)
	ld $(L_FLAGS) -Map=stage2.map $(OBJS) -o stage2.elf
	objcopy -O binary stage2.elf stage2.bin	

clean:
	rm -f *.o *.map *.elf *.bin

.PHONY: all clean