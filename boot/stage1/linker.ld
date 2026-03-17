ENTRY(start)

SECTIONS
{
	. = 0x7C00;

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

	. = 0x7C00 + 0x200 - 0x2;

	.boot_sig :
	{
		SHORT(0xAA55)
	}
}