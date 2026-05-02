# t08_jalr.s - JALR (Jump And Link Register)
# Tests: Unconditional jump using register value as target address
# Expected final registers (RARS run):
#   x20 = 0x000007CE
#   x30 = 0x00000000   (skip path)

addi x1, x0, 0x10     # x1 = 0x10 (target address)
addi x1, x1, 0        # x1 = 0x10 (ensure x1 is set)
addi x0, x0, 0        # NOP
addi x0, x0, 0        # NOP
ori x20, x0, 0x7ce    # x20 = 0x7CE (instruction before JALR)
jalr x5, x1, 0        # Jump to address in x1, save return address to x5
addi x30, x0, 123     # should be SKIPPED
end:
beq x0, x0, end       # Infinite loop
