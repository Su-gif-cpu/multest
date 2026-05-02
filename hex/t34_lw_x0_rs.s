# t34_lw_x0_rs - lw 目标 x0 后，用 x0 作 addi 的 rs1（读端口必须为 0）
# 期望: x21 = 5
# RARS: mc CompactDataAtZero

addi x1, x0, 0x20
ori  x2, x0, 0x077
sw   x2, 0(x1)
lw   x0, 0(x1)
addi x21, x0, 5
end:
beq  x0, x0, end
