# t37_beq_fallthrough2 - 连续 beq 条件均假，必须顺序执行到 addi
# 期望: x20 = 0x3D
# RARS: mc CompactTextAtZero

addi x1, x0, 1
addi x2, x0, 2
beq  x1, x2, join
beq  x2, x1, join
addi x20, x0, 0x3D
join:
beq  x0, x0, join
