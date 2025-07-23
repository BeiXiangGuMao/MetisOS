/* kernel/include/kernel.h */
#pragma once
#include <stddef.h>

/* 与 newlib 完全不冲突的函数名 */
void kernel_putchar(int c);
int  kernel_puts(const char *s);
void kernel_main(void);