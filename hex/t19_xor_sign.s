# t19_xor_sign - 负数与正数 xor
# 期望: x20 = 0xFFFFFFFE
# RARS: mc CompactTextAtZero

addi x1, x0, -1
addi x2, x0, 1
xor  x20, x1, x2
end:
beq  x0, x0, end
