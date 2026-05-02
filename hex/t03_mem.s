# t03_mem.s - lw/sw timing and negative offset
# PASS condition: x5 == 0x456

addi x1, x0, 0x20     # base address
ori  x2, x0, 0x123
sw   x2, 0(x1)        # write then immediate read
lw   x3, 0(x1)

ori  x4, x0, 0x456
sw   x4, -4(x1)       # negative offset address computation
lw   x5, -4(x1)       # immediate read-after-write on negative offset

end:
beq  x0, x0, end
