# t27_sra_neg1 - -1 算术右移 1 位仍为 -1
# 期望: x20 = 0xFFFFFFFF
# RARS: mc CompactTextAtZero

addi x1, x0, -1
addi x2, x0, 1
sra  x20, x1, x2
end:
beq  x0, x0, end
