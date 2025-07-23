/* metis/ld/linker-kernel.ld */
ENTRY(kernel_main)

SECTIONS
{
    /* 物理地址 1 MiB，QEMU -kernel 默认加载地址 */
    . = 0x100000;

    .text : ALIGN(4K)
    {
        *(.text.start)   /* 启动 stub */
        *(.text*)
    }

    .rodata : ALIGN(4K)
    {
        *(.rodata*)
    }

    .data : ALIGN(4K)
    {
        *(.data*)
    }

    .bss : ALIGN(4K)
    {
        *(.bss*)
        *(COMMON*)
    }

    /DISCARD/ : { *(.note*) *(.comment*) }
}