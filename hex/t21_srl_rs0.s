# t21_srl_rs0 - 移位量来自 x0（低 5 位为 0）
# 期望: x20 = 0x7B
# RARS: mc CompactTextAtZero

addi x1, x0, 0x7B
srl  x20, x1, x0
end:
beq  x0, x0, end
