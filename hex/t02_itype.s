# t02_itype.s - I-type immediate and sign-extension
# PASS condition: x4 == 0xFFFFFF01

addi x1, x0, -1       # critical: 0xFFF must sign-extend to 0xFFFFFFFF
addi x2, x1, 1        # result must be zero
ori  x3, x0, -256     # sign-extended immediate OR test
addi x4, x3, 1        # 0xFFFFFF00 + 1 = 0xFFFFFF01

end:
beq  x0, x0, end
