# t35_mem_chain_offsets - 多组 sw 紧接 lw，再用负偏移搬运字
# 期望: x20 = 0x101
# RARS: mc CompactDataAtZero

addi x1, x0, 0x40
ori  x2, x0, 0x101
sw   x2, 0(x1)
lw   x3, 0(x1)
ori  x4, x0, 0x202
sw   x4, 4(x1)
lw   x5, 4(x1)
sw   x3, -8(x1)
lw   x20, -8(x1)
end:
beq  x0, x0, end
