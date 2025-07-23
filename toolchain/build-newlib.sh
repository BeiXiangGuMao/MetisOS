#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PREFIX="$ROOT/out/gcc-x86_64-elf"
BUILD="$ROOT/out/build-gcc"
NEWLIB_BUILD="$ROOT/out/build-newlib"
PARALLEL=$(nproc)
# 3. 环境变量
export PATH="$PREFIX/bin:$PATH"
export TARGET=x86_64-elf

# 4. Binutils
mkdir -p "$BUILD/binutils"
cd "$BUILD/binutils"
"$ROOT/out/src/binutils-2.41/configure" \
    --target=$TARGET --prefix="$PREFIX" \
    --with-sysroot --disable-nls --disable-werror
make -j$PARALLEL
make install

# 5. 极简 GCC（仅 C 语言，先不 newlib）
mkdir -p "$BUILD/gcc"
cd "$BUILD/gcc"
"$ROOT/out/src/gcc-13.2.0/configure" \
    --target=$TARGET --prefix="$PREFIX" \
    --disable-nls --enable-languages=c --without-headers
make all-gcc -j$PARALLEL
make install-gcc

# 6. newlib（现在能找到 x86_64-elf-gcc）
mkdir -p "$NEWLIB_BUILD"
cd "$NEWLIB_BUILD"
"$ROOT/out/src/newlib-4.3.0/configure" \
    --target=$TARGET --prefix="$PREFIX" \
    --disable-shared --enable-newlib-reent-small \
    --disable-newlib-fvwrite-in-streamio --disable-nls
make -j$PARALLEL
make install

echo "[OK] 交叉工具链 + newlib 完整安装到 $PREFIX"