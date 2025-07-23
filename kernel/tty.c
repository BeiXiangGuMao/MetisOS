/* kernel/tty.c */
#include "include/kernel.h"
static inline void outb(unsigned short p, unsigned char v){
    __asm__ volatile ("outb %0,%1" :: "a"(v), "Nd"(p));
}
void kernel_putchar(int c) { outb(0x3F8, (char)c); }
int  kernel_puts(const char *s){
    while(*s) kernel_putchar(*s++);
    kernel_putchar('\n');
    return 0;
}