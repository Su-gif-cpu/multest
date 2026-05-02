# t10_loop_bne.s - Loop with BNE (Backward Jump)
# Tests: Backward branch with negative offset
# Expected final registers:
#   x1 = 0x00000003
#   x2 = 0x00000003

addi x1, x0, 0        # x1 = 0 (loop counter)
loop:
addi x1, x1, 1        # x1 = 1 (x1++)
addi x2, x0, 3        # x2 = 3 (loop condition)
bne x1, x2, loop      # x1 != 3, backward branch
# Loop exits when x1 == 3
end:
beq x0, x0, end       # Infinite loop after loop finishes
#
# Expected: x1 = 3 after loop completes (incremented from 0 to 3 in 3 iterations)
