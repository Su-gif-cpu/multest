# t08_jalr.s - JALR：PC 相对目标 + 可证伪的通过条件
#
# 1) 末尾 beq 自旋在 RARS 里会跑到「步数上限」才停——这是裸机测例常见写法，不是 CPU 死机；
#    若要在 RARS 里立刻结束，需实现 ebreak 等（本工程 16 条指令子集未包含）。
#
# 2) 不能仅用 x30==0 判通过：复位后 x30 已是 0，无法区分「跳过坏路」与「从未写过」。
#    故在入口 ori x30,0,0x42 作哨兵；任一条坏路 addi x30,123 会把 x30 改成 123。
#    通过条件（VCS / RARS）：x30 == 0x42。
#
# RARS: mc CompactTextAtZero

    ori  x30, x0, 0x42
    jal  x1, L1
L_bad:
    addi x30, x0, 123
L1:
    addi x2, x1, 16
    jalr x5, x2, 0
    addi x30, x0, 123
L_target:
    beq  x0, x0, L_target