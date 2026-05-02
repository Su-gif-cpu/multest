# t28_bne_taken - bne 成立跳过中间
# 期望: x20 = 0x56
# RARS: mc CompactTextAtZero

addi x1, x0, 1
addi x2, x0, 2
bne  x1, x2, skip
addi x20, x0, 0xFF
skip:
addi x20, x0, 0x56
end:
beq  x0, x0, end
