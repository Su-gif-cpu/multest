# t30_sw_lw_min_offset - S/L 型立即数下界 -2048（基址+负立即数=0）
# 期望: x20 = 0x000003EF
# RARS: mc CompactDataAtZero
# 注: addi 单条立即数最大 2047，用两条得到基址 2048

addi x1, x0, 2047
addi x1, x1, 1
ori  x2, x0, 0x3EF
sw   x2, -2048(x1)
lw   x20, -2048(x1)
end:
beq  x0, x0, end
