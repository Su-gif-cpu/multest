# t17_addi_bounds - 12-bit立即数边界 addi(-2048) / addi(+2047)
# 期望: x20 = 0xFFFFFFFF（-2048 + 2047 = -1）
# RARS: mc CompactTextAtZero

addi x1, x0, -2048
addi x2, x0, 2047
add  x20, x1, x2
end:
beq  x0, x0, end
