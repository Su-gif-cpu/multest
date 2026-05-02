# t20_sub_self - 同寄存器相减
# 期望: x20 = 0
# RARS: mc CompactTextAtZero

addi x1, x0, 0x55
sub  x20, x1, x1
end:
beq  x0, x0, end
