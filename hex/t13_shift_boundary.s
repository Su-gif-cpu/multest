# t13_shift_boundary.s - shift boundary coverage
# Includes shift amount 0 and 31, and SRA sign behavior.
# PASS condition: x13 == 0

addi x1, x0, 1
addi x2, x0, -1
ori  x3, x0, 0x7ff
addi x4, x0, 31

sll  x8,  x1, x0      # shift amount = 0
sll  x9,  x1, x4      # shift amount = 31
srl  x10, x9, x0      # shift amount = 0
srl  x11, x2, x4      # 0xFFFFFFFF >> 31 = 1
sra  x12, x2, x4      # negative arithmetic right shift -> all 1
sra  x13, x3, x4      # positive arithmetic right shift -> 0

end:
beq  x0, x0, end
