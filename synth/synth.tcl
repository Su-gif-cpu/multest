# ==============================================================================
# Design Compiler Synthesis Script (synth.tcl)
# Target Frequency: 200MHz (Period: 5.0ns)
# Target Flow: Tape-out Oriented High-Performance Optimization
# ==============================================================================

# # 1. 读入 RTL 源代码
set file_list [list \
  ../rtl/includes/global_def.v \
  ../rtl/includes/ctrl_signal_def.v \
  ../rtl/includes/instruction_def.v \
  ../rtl/ALU.v \
  ../rtl/ControlUnit.v \
  ../rtl/DM.v \
  ../rtl/EXT.v \
  ../rtl/Flopr.v \
  ../rtl/IM.v \
  ../rtl/IR.v \
  ../rtl/MUX_2to1_A.v \
  ../rtl/MUX_3to1_B.v \
  ../rtl/MUX_3to1.v \
  ../rtl/MUX_3to1_LMD.v \
  ../rtl/NPC.v \
  ../rtl/PC.v \
  ../rtl/RF.v \
  ../rtl/riscv.v \
]

analyze -format verilog $file_list
elaborate riscv
current_design riscv
link

# # 2. 施加时序与物理环境约束
create_clock -name sys_clk -period 5.0 [get_ports clk]
set_ideal_network [get_ports clk]
set_ideal_network [get_ports rst]

# 物理约束：设置 100ps 时钟不确定度（涵盖 Jitter + Skew）
set_clock_uncertainty 0.1 [get_clocks sys_clk]

# 输入输出延迟预算 (20% clock period)
set_input_delay 1.0 -clock sys_clk [remove_from_collection [all_inputs] clk]
set_output_delay 1.0 -clock sys_clk [all_outputs]

# 严格限制最大转换时间（Transition）和负载，强制工具插入高性能 Buffer
set_max_transition 0.5 [current_design]
set_max_capacitance 1.0 [current_design]

# # 3. 保护硬核（SRAM 宏）
set_dont_touch [get_cells U_IM/memory]
set_dont_touch [get_cells U_DM/memory]

# # 4. 时序优化策略
# 4.1 忽略面积，100% 算力倾斜至时序
set_max_area 0

# 4.2 扩大优化范围（将关键路径周围 1.0ns 范围内的所有路径均纳入极致优化对象）
set_critical_range 1.0 [current_design]

# 4.3 强化目标时钟路径权重（分配10倍优先级）
group_path -name sys_clk -weight 10 -critical_range 1.0

# # 5. 开启形式验证引导记录
set_svf ./outputs/riscv.svf

# # 6. 两阶段综合编译流程
# 第一阶段：高强度编译 + 寄存器重配（Retiming）
compile_ultra -retime -timing_high_effort_script

# 第二阶段：增量物理层细调（在现有网表基础上进行门尺寸 sizing 和物理重构）
compile_ultra -incremental -retime -timing_high_effort_script

# # 7. 导出综合成果物
write -format verilog -hierarchy -output ./outputs/riscv_synth.v
write_sdc ./outputs/riscv.sdc
write_sdf ./outputs/riscv.sdf

# # 8. 导出多维度分析报告
report_timing -delay_type max -max_paths 10 > ./reports/timing_max.rpt
report_area -hierarchy > ./reports/area.rpt
report_power > ./reports/power.rpt
report_constraint -all_violators > ./reports/violators.rpt

set_svf -off
exit