# t38_sub_from_zero - 0 - 0x80000000（32 位补码回绕）
# 期望: x20 = 0x80000000
# RARS: mc CompactTextAtZero

addi x1, x0, 1
addi x2, x0, 31
sll  x3, x1, x2
sub  x20, x0, x3
end:
beq  x0, x0, end
