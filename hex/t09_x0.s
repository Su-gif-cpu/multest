# t09_x0.s - x0 hardwired-zero checks
# PASS condition: x1 == 0x66

addi x2, x0, 0x10
ori  x3, x0, 0x55
sw   x3, 0(x2)

addi x0, x2, 10       # try to write x0 by ALU path
lw   x0, 0(x2)        # try to write x0 by load path

addi x1, x0, 0x66     # must still read x0 as 0
end:
beq  x0, x0, end
