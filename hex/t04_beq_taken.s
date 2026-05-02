# t04_beq_taken.s - BEQ (Branch if Equal) - Condition Satisfied
# Tests: Branch taken when rs1 == rs2
# Expected final registers:
#   x1 = 0x00000005
#   x2 = 0x00000005
#   x3 = 0x00000000   (branch taken, ori skipped)
#   x4 = 0x00000001

addi x3, x0, 0        # x3 = 0 (initialize)
addi x1, x0, 5        # x1 = 5
addi x2, x0, 5        # x2 = 5 (x1 == x2)
beq x1, x2, target    # x1 == x2, branch taken
addi x3, x0, 123      # should be skipped
target:
addi x4, x0, 1        # branch target, should execute
end:
beq x0, x0, end       # Infinite loop
