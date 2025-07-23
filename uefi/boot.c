/* uefi/boot.c */
#define __UEFI__          /* 告诉头文件走 UEFI 分支 */
#include <stdint.h>
#include "../kernel/include/kernel.h"

/* 简化 EFI 定义，够用即可 */
typedef uint64_t EFI_STATUS;
typedef uint16_t CHAR16;
typedef struct {
    void *dummy[24];
} EFI_SYSTEM_TABLE;

EFI_STATUS efi_main(void *ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
    (void)ImageHandle;
    (void)SystemTable;

    /* UEFI 环境下可直接用 newlib printf，但这里先最小化 */
    kernel_main();          /* 调用公共内核 */
    return 0;
}
