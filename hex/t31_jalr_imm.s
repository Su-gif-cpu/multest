# t31_jalr_imm - jalr 非零立即数：target = rs1 + imm
# 流程: jal 跳过 L1；L2 用 x5+4 与 imm=-4 回到 L1；再 jal 到自旋
# 期望: x20 = 0xCC
# RARS: mc CompactTextAtZero

jal  x5, L2
L1:
addi x20, x0, 0xCC
jal  x0, end
L2:
addi x10, x5, 4
jalr x0, x10, -4
end:
beq  x0, x0, end
