# t23_beq_always - beq x0,x0 恒成立跳过中间指令
# 期望: x20 = 0x42（中间 addi x20,1 被跳过）
# RARS: mc CompactTextAtZero

beq  x0, x0, skip
addi x20, x0, 1
skip:
addi x20, x0, 0x42
end:
beq  x0, x0, end
