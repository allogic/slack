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

	. = 0x8000 + 0x10000 - 0x2;

	.boot_sig :
	{
		SHORT(0xDEAD)
	}
}