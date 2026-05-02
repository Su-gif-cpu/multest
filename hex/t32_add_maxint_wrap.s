# t32_add_maxint_wrap - 构造 0x7FFFFFFF 后 +1 回绕到 0x80000000（无异常）
# 期望: x20 = 0x80000000
# RARS: mc CompactTextAtZero

addi x1, x0, 1
addi x2, x0, 31
sll  x3, x1, x2
addi x4, x0, -1
xor  x5, x4, x3
add  x20, x5, x1
end:
beq  x0, x0, end
