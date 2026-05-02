# t33_sra_pos_msb - 正数最高位为 0，sra 31 位应为 0
# 期望: x20 = 0
# RARS: mc CompactTextAtZero

addi x1, x0, 1
addi x2, x0, 30
sll  x3, x1, x2
addi x4, x0, 31
sra  x20, x3, x4
end:
beq  x0, x0, end
