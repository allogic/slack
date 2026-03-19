ASM_FLAGS += -i.
ASM_FLAGS += -f elf64
ASM_FLAGS += -F dwarf
ASM_FLAGS += -g

C_FLAGS += -I.
C_FLAGS += -c
C_FLAGS += -g
C_FLAGS += -O0
C_FLAGS += -m64
C_FLAGS += -mno-red-zone
C_FLAGS += -nostdlib
C_FLAGS += -nodefaultlibs
C_FLAGS += -ffreestanding
C_FLAGS += -fno-stack-protector
C_FLAGS += -fno-pic
C_FLAGS += -ffunction-sections
C_FLAGS += -Wall
C_FLAGS += -Wextra

L_FLAGS += -melf_x86_64
L_FLAGS += -nostdlib
L_FLAGS += -T linker.ld

ASM_SRCS += kernel.s # Must be first to be loaded at 0x100000

C_SRCS += main.c

OBJS = $(ASM_SRCS:.s=.o) $(C_SRCS:.c=.o)

%.o: %.s
	nasm $(ASM_FLAGS) $< -o $@

%.o: %.c
	gcc $(C_FLAGS) $< -o $@

all: $(OBJS)
	ld $(L_FLAGS) -Map=kernel.map $(OBJS) -o kernel.elf
	objcopy -O binary kernel.elf kernel.bin	

clean:
	rm -f *.o *.map *.elf *.bin

.PHONY: all clean