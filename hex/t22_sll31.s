# t22_sll31 - 1 << 31
# 期望: x20 = 0x80000000
# RARS: mc CompactTextAtZero

addi x1, x0, 1
addi x2, x0, 31
sll  x20, x1, x2
end:
beq  x0, x0, end
