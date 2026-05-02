# t29_or_combine - ori 与已有模式按位或
# 期望: x20 = 0xFF (= 0xF0 | 0x0F)
# RARS: mc CompactTextAtZero

addi x1, x0, 0xF0
ori  x20, x1, 0x00F
end:
beq  x0, x0, end
