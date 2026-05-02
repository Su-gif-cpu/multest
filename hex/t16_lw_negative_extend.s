# t16_lw_negative_extend.s - branch/jump mixed control flow
# Covers backward branch, forward jal, and jalr.
# PASS condition: x9 == 0x00000028

addi x1, x0, 0
addi x2, x0, 3
addi x3, x0, 0
loop:
addi x3, x3, 1
bne  x3, x2, loop      # backward (negative offset)

jal  x5, after_skip     # forward (positive offset)
addi x6, x0, 0x11       # skipped
after_skip:
addi x7, x0, 0x22

addi x10, x0, 44        # absolute target used by jalr
jalr x9, x10, 0         # x9 gets return address 40 (0x28)
addi x11, x0, 0x33      # skipped if jalr works

end:
beq  x0, x0, end
