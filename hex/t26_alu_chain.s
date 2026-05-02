# t26_alu_chain - 连续 RAW 依赖 add 链（多周期冒险压力）
# 期望: x20 = 16
# RARS: mc CompactTextAtZero

addi x1, x0, 1
add  x2, x1, x1
add  x3, x2, x2
add  x4, x3, x3
add  x20, x4, x4
end:
beq  x0, x0, end
