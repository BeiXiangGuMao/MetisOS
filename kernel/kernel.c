/* kernel/kernel.c */
#include "include/kernel.h"
void kernel_main(void){
    kernel_puts("Hello x86_64 bare-metal with newlib!");
    for(;;);
}