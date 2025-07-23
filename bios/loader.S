.code32
.global _start
_start:
    cli
    lgdt gdt64_ptr
    mov %cr0, %eax
    or  $1, %ax
    mov %eax, %cr0
    ljmp $0x08, $long_mode
.code64
long_mode:
    mov $0x10, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %ss
    mov $0x90000, %rsp
    jmp kernel_main

.align 8
gdt64:
    .quad 0x0000000000000000
    .quad 0x00af9a000000ffff   # code
    .quad 0x00af92000000ffff   # data
gdt64_ptr:
    .short gdt64_ptr - gdt64 - 1
    .long gdt64