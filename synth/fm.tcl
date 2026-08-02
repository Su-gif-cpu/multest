################################################################################
# Formality Equivalence Checking Script for riscv
################################################################################

# 1. 基础环境与搜索路径配置
#set sh_enable_line_editing true
set_app_var search_path ". ../rtl ../rtl/includes"

# 定义工艺库与 SRAM 库路径（参考自你的 .synopsys_dc.setup 和 synth.tcl）
set STCELL_DIR "/home/library/tsmc65lp/std/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn65lp_220a"
set SRAM_DIR   "/home/library/tsmc65lp/sram/ts1n65lpll2048x64m8_220a/SYNOPSYS"

# 载入工艺库（Formality 使用 read_db 读取 .db 文件）
read_db -technology_library "$STCELL_DIR/tcbn65lpwc.db"
read_db -technology_library "$SRAM_DIR/ts1n65lpll2048x64m8_220a_ss1p08v125c.db"

# 2. 读入 SVF 指导文件（极为关键：用于指导 Retiming、Ungroup 等优化行为的等价性对齐）
set_svf ./outputs/riscv.svf


# 3. 读入并设置 Reference 设计 (Golden RTL)
# 创建 Reference 容器 (r)
create_container r

# 读入 RTL 源代码（顺序和文件列表与你的 synth.tcl 保持一致）
read_verilog -container r {
    ../rtl/includes/global_def.v
    ../rtl/includes/ctrl_signal_def.v
    ../rtl/includes/instruction_def.v
    ../rtl/ALU.v
    ../rtl/ControlUnit.v
    ../rtl/DM.v
    ../rtl/EXT.v
    ../rtl/Flopr.v
    ../rtl/IM.v
    ../rtl/IR.v
    ../rtl/MUX_2to1_A.v
    ../rtl/MUX_3to1_B.v
    ../rtl/MUX_3to1.v
    ../rtl/MUX_3to1_LMD.v
    ../rtl/NPC.v
    ../rtl/PC.v
    ../rtl/RF.v
    ../rtl/riscv.v
}

# 设置 RTL 顶层设计
set_top r:/work/riscv


# 4. 读入并设置 Implementation 设计 (Revised Netlist)
# 创建 Implementation 容器 (i)
create_container i

# 读入综合输出的网表文件
read_verilog -container i -netlist ./outputs/riscv_synth.v

# 设置网表顶层设计
set_top i:/work/riscv


# 5. 关键匹配与验证准备
# Formality 会尝试自动匹配 Reference 和 Implementation 中的关键点（寄存器、端口、黑盒子等）
match

# 6. 执行等价性校验
verify


# 7. 生成分析报告并导出
# 检查是否有未成功匹配的点或验证失败的点
report_unmatched_points > ./reports/fm_unmatched_points.rpt
report_failing_points   > ./reports/fm_failing_points.rpt
report_passing_points   > ./reports/fm_passing_points.rpt

# 输出比对状态摘要
report_status