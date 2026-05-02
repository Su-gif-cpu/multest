# t14_add_negative.s - Arithmetic Instructions with Negative Numbers
# Tests: add/sub with negative operands to verify sign handling

addi x1, x0, -1       # x1 = 0xFFFFFFFF (negative 1)
addi x2, x0, -2       # x2 = 0xFFFFFFFE (negative 2)
add x8, x1, x2        # x8 = (-1) + (-2) = 0xFFFFFFFD (negative + negative = negative)

addi x3, x0, 5        # x3 = 0x00000005
add x9, x1, x3        # x9 = (-1) + 5 = 0x00000004 (negative + positive)

sub x10, x1, x3       # x10 = (-1) - 5 = 0xFFFFFFFA (negative - positive = more negative)

sub x11, x2, x1       # x11 = (-2) - (-1) = 0xFFFFFFFF (negative - negative = depends on magnitudes)

addi x5, x0, 16       # x5 = 0x10
sub x12, x5, x1       # x12 = 16 - (-1) = 0x00000011 (positive - negative = positive)

addi x13, x1, 1       # x13 = (-1) + 1 = 0x00000000 (negative + positive = zero)

end:
beq x0, x0, end       # Infinite loop
#
# Expected Results:
# x8 = 0xFFFFFFFD (negative sum)
# x9 = 0x00000004 (mixed signs)
# x10 = 0xFFFFFFFA (negative - positive)
# x11 = 0xFFFFFFFF (-2 - (-1) = -1)
# x12 = 0x00000011 (positive result)
# x13 = 0x00000000 (zero result)
