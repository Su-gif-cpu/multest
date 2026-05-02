# t15_bne_false.s - BNE not-taken paths
# PASS condition: x8 == 0x88

addi x1, x0, 0x55
addi x2, x0, 0x55
bne  x1, x2, skip1    # not taken
addi x5, x0, 0xaa
skip1:

addi x3, x0, 0
addi x4, x0, 0
bne  x3, x4, skip2    # not taken
ori  x8, x0, 0x88
skip2:

end:
beq  x0, x0, end
