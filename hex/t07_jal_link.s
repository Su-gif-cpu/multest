# t07_jal_link.s - JAL (Jump And Link)
# Tests: Unconditional jump with return address saved to rd
# Expected final registers:
#   x10 = 0x00002004   (link address: PC+4)
#   x11 = 0x00000000   (skipped)
#   x12 = 0x00000001

jal x10, target       # Jump to label, save return address (PC+4) to x10
addi x11, x0, 123     # should be SKIPPED
target:
addi x12, x0, 1       # x12 = 1 (jump target, should execute)
end:
beq x0, x0, end       # Infinite loop
