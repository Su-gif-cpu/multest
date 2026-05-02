# t25_sw_overwrite - 同一字地址连续 sw 覆盖后 lw
# 期望: x20 = 0x00000222
# RARS: mc CompactDataAtZero（与仿真 DM 基址一致）

addi x1, x0, 0x20
ori  x2, x0, 0x111
sw   x2, 0(x1)
ori  x3, x0, 0x222
sw   x3, 0(x1)
lw   x20, 0(x1)
end:
beq  x0, x0, end
