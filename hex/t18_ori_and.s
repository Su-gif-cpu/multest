# t18_ori_and - ori 立即数符号扩展后与 and
# 期望: x20 = 0x000007FF
# RARS: mc CompactTextAtZero

ori  x1, x0, 2047
ori  x2, x0, -1
and  x20, x1, x2
end:
beq  x0, x0, end
