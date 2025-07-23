.code16
.global _start
_start:
    jmp 0x0000:0x8000     # 跳到 loader 起始
.fill 510-(.-_start),1,0
.word 0xaa55