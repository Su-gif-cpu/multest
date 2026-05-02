# t05_beq_not_taken.s - BEQ (Branch if Equal) - Condition NOT Satisfied
# Tests: Sequential execution when rs1 != rs2
# Expected final registers:
#   x1 = 0x00000001
#   x2 = 0x00000002
#   x3 = 0x00000099
#   x5 = 0x00000001

addi x1, x0, 1        # x1 = 1
addi x2, x0, 2        # x2 = 2 (x1 != x2)
beq x1, x2, target    # x1 != x2, so branch is NOT TAKEN
ori x3, x0, 0x99      # x3 = 0x99 (should execute)
addi x5, x0, 1        # x5 = 1
target:
end:
beq x0, x0, end       # Infinite loop
