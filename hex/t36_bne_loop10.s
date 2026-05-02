# t36_bne_loop10 - bne 向后跳转计数到 10（多周期取指压力）
# 期望: x20 = 10
# RARS: mc CompactTextAtZero

addi x20, x0, 0
addi x2, x0, 10
L:
addi x20, x20, 1
bne  x20, x2, L
end:
beq  x0, x0, end
