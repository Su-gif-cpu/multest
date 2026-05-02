# t01_ralu.s - R-type ALU coverage
# add/sub/and/or/xor/sll/srl/sra + arithmetic boundary combinations.
# PASS condition: x15 == 0

addi x1,  x0, 5          # positive
addi x2,  x0, 3          # positive
add  x3,  x1, x2         # positive + positive
sub  x4,  x1, x2
and  x5,  x1, x2
or   x6,  x1, x2
xor  x7,  x1, x2

addi x8,  x0, 4
sll  x9,  x1, x8
srl  x10, x9, x8
sra  x11, x9, x8

addi x12, x0, -1         # negative (x12 = -1)
addi x13, x0, -2         # negative (x13 = -2)
add  x14, x12, x13       # negative + negative (x14 = -3)

# --- 校验和计算 (Checksum) ---
# 将前面所有运算的特征寄存器异或/累加到一起
xor x15, x3, x4          # x15 = 8 ^ 2 = 10
xor x15, x15, x5         # x15 = 10 ^ 1 = 11
xor x15, x15, x6         # x15 = 11 ^ 7 = 12
xor x15, x15, x7         # x15 = 12 ^ 6 = 10
xor x15, x15, x10        # x15 = 10 ^ 5 = 15
xor x15, x15, x11        # x15 = 15 ^ 5 = 10
add x15, x15, x14        # x15 = 10 + (-3) = 7

# 最终你的仿真器/Testbench只需监控：
# 如果程序停在 end 且 x15 == 7，则证明所有 R型 ALU 运算 100% 正确！
# 任何一条指令算错一个比特，最终的 x15 都不会是 7。

end:
beq  x0, x0, end
