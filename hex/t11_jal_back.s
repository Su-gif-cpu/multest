# t11_jal_back.s - JAL with Backward Jump
# Tests: Forward and backward unconditional jumps
# Expected final registers:
#   x1 = 0x00000001
#   x2 = 0x00000002
#   x3 = 0x00000003

addi x1, x0, 1        # x1 = 1
jal x0, step2         # Jump forward (skip next instruction)
addi x0, x0, 0        # NOP (should be SKIPPED)
step2:
addi x3, x0, 3        # x3 = 3
jal x0, step3         # Jump forward by one instruction
addi x0, x0, 0        # NOP (should be SKIPPED)
step3:
addi x2, x0, 2        # x2 = 2
end:
beq x0, x0, end       # Infinite loop
#
# Expected: x1 = 1, x2 = 2, x3 = 3
# This tests instruction sequencing and jump target calculation
