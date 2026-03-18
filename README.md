# Slack
x64 toy kernel written in C.

### Common Commands
```
readelf -s kernel.elf
hexdump -C -n 32 kernel.bin
x/32xb 0x0
```

### Memory Map
```
Start      End        Size      Name
---------------------------------------
0x0        0x7C00     0x7C00    Bios
0x7C00     0x8000     0x200     Stage1
0x8000     0x18000    0x10000   Stage2
0x18000    0x100000   0xE8000   MMap
0x100000   0x?        0x?       Kernel
```