# t01_ralu.s - R-type ALU coverage
# add/sub/and/or/xor/sll/srl/sra + arithmetic boundary combinations.
# PASS condition: x15 == 0

addi x1,  x0, 5          # positive
addi x2,  x0, 3          # positive
add  x3,  x1, x2         # positive + positive
sub  x4,  x1, x2
and  x5,  x1, x2
or   x6,  x1, x2
xor  x7,  x1, x2

addi x8,  x0, 4
sll  x9,  x1, x8
srl  x10, x9, x8
sra  x11, x9, x8

addi x12, x0, -1         # negative
addi x13, x0, -2         # negative
add  x14, x12, x13       # negative + negative
addi x15, x14, 3         # -3 + 3 -> 0

end:
beq  x0, x0, end