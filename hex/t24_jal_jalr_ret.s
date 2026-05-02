# t24_jal_jalr_ret - jal 保存返回地址，jalr 返回后继续执行
# 期望: x20 = 0x33, x21 = 0xAA
# RARS: mc CompactTextAtZero

jal  x5, callee
addi x21, x0, 0xAA
callee:
addi x20, x0, 0x33
jalr x0, x5, 0
end:
beq  x0, x0, end
