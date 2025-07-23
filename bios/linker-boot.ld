ENTRY(_start)

SECTIONS {
    . = 0x7c00;
    .mbr : { bios/mbr.o(.text) }
    . = 0x8000;
    .loader : { bios/loader.o(.text) }
    . = 0x100000;
    .kernel : { kernel/kernel.o(.text*) kernel/tty.o(.text*) }
}