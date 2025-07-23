###############################################################################
# MetisOS 统一构建脚本  (2025-06-25 版)
###############################################################################
SHELL       := /bin/bash
ROOT        := $(shell pwd)
OUT         := $(ROOT)/out
PREFIX      := $(strip $(ROOT)/out/gcc-x86_64-elf)
CROSS       := $(PREFIX)/bin/x86_64-elf-
CC          := $(CROSS)gcc
LD          := $(CROSS)ld
OBJCP       := $(CROSS)objcopy
QEMU        := qemu-system-x86_64
MKFS_FAT    := mkfs.fat
MCOPY       := mcopy

# 固件路径探测
OVMF_CODE   := $(wildcard /usr/share/qemu/OVMF.fd \
                           /usr/share/OVMF/OVMF_CODE.fd \
                           /usr/share/ovmf/OVMF.fd)
ifeq ($(OVMF_CODE),)
    $(error OVMF not found. 安装：sudo apt install ovmf)
endif

# newlib / libgcc 路径
NEWLIB_INC  := $(PREFIX)/x86_64-elf/include
NEWLIB_LIB  := $(PREFIX)/x86_64-elf/lib
GCC_LIB     := $(PREFIX)/lib/gcc/x86_64-elf/13.2.0

###############################################################################
# 通用编译 / 链接标志
###############################################################################
CFLAGS_COMMON := -ffreestanding -m64 -mno-red-zone -mcmodel=kernel \
                 -nostdlib -I$(NEWLIB_INC)

LDFLAGS_COMMON := -nostdlib -L$(NEWLIB_LIB) -L$(GCC_LIB) -lc -lgcc

###############################################################################
# 文件列表
###############################################################################
BIOS_OBJS := bios/mbr.o bios/loader.o kernel/kernel.o kernel/tty.o
UEFI_OBJS := uefi/boot.obj kernel/kernel.obj kernel/tty.obj

###############################################################################
# 默认目标
###############################################################################
.PHONY: all clean bios-img uefi-img run-bios run-uefi

all: bios-img uefi-img

###############################################################################
# BIOS 启动链（MBR + Loader）
###############################################################################
bios-img: $(OUT)/metis-bios.img

$(OUT)/metis-bios.img: $(BIOS_OBJS)
	@mkdir -p $(OUT)
	$(LD) -T bios/linker-boot.ld $^ $(LDFLAGS_COMMON) -o $(OUT)/bios.elf
	$(OBJCP) -O binary $(OUT)/bios.elf $@

bios/mbr.o: bios/mbr.S
	@mkdir -p $(dir $@)
	$(CROSS)as -m16 $< -o $@

bios/loader.o: bios/loader.S
	@mkdir -p $(dir $@)
	$(CROSS)as -m32 $< -o $@

###############################################################################
# UEFI 启动链（PE32+ EFI 可执行）
###############################################################################
uefi-img: $(OUT)/metis-uefi.img

# 1. 用 clang 把 .c 编译成 COFF .obj
CLANG      := clang
UEFI_FLAGS := -target x86_64-unknown-windows -ffreestanding \
              -mno-red-zone -mcmodel=small -O2 \
              -I$(NEWLIB_INC)

uefi/%.obj: uefi/%.c
	@mkdir -p $(dir $@)
	$(CLANG) $(UEFI_FLAGS) -c $< -o $@

kernel/%.obj: kernel/%.c
	@mkdir -p $(dir $@)
	$(CLANG) $(UEFI_FLAGS) -c $< -o $@

# 2. 用 lld-link 链接成 PE32+ EFI
$(OUT)/bootx64.efi: $(UEFI_OBJS)
	@mkdir -p $(OUT)
	lld-link -subsystem:efi_application -entry:efi_main \
	         -out:$@ $^ \
	         -libpath:$(NEWLIB_LIB) \
	         -libpath:$(GCC_LIB) \
	         $(NEWLIB_LIB)/libc.a \
	         $(GCC_LIB)/libgcc.a

# 3. 打包 FAT 镜像
$(OUT)/metis-uefi.img: $(OUT)/bootx64.efi
	@mkdir -p $(OUT)/efi/boot
	cp $(OUT)/bootx64.efi $(OUT)/efi/boot/BOOTX64.EFI
	dd if=/dev/zero of=$@ bs=1M count=64
	$(MKFS_FAT) $@ >/dev/null
	mmd -i $@ ::EFI         >/dev/null 2>&1 || true
	mmd -i $@ ::EFI/BOOT   >/dev/null 2>&1 || true
	$(MCOPY) -i $@ $(OUT)/efi/boot/BOOTX64.EFI ::EFI/BOOT/ >/dev/null

###############################################################################
# 运行
###############################################################################
run-bios: bios-img
	$(QEMU) -m 512M -cpu qemu64 \
	        -drive file="$(OUT)/metis-bios.img",format=raw,if=floppy \
	        -serial mon:stdio

# OVMF 固件路径
OVMF_CODE := $(wildcard /usr/share/qemu/OVMF.fd)
OVMF_CODE := $(or $(OVMF_CODE),$(wildcard /usr/share/OVMF/OVMF_CODE.fd))
OVMF_CODE := $(or $(OVMF_CODE),$(wildcard /usr/share/ovmf/OVMF.fd))

ifeq ($(OVMF_CODE),)
    $(error "OVMF 固件未找到，请安装 ovmf 软件包")
endif

# UEFI 启动命令
run-uefi: uefi-img
	$(QEMU) -m 512M -cpu qemu64 \
	        -drive file="$(OUT)/metis-uefi.img",format=raw,if=virtio \
	        -drive file="$(OVMF_CODE)",if=pflash,readonly=on \
	        -serial mon:stdio

###############################################################################
# 清理
###############################################################################
clean:
	rm -rf $(OUT)
