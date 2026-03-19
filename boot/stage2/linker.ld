ENTRY(start)

SECTIONS
{
	. = 0x8000;

	.text :
	{
		*(.text*)
	}

	.rodata :
	{
		*(.rodata*)
	}

	.data :
	{
		*(.data*)
	}

	.bss :
	{
		*(.bss*)
	}

	idt_pm :
	{
		. = ALIGN(0x8);
		*(.idt_pm*)
	}

	idt_lm :
	{
		. = ALIGN(0x10);
		*(.idt_lm*)
	}

	. = 0x8000 + 0x10000 - 0x2;

	.boot_sig :
	{
		SHORT(0xDEAD)
	}
}