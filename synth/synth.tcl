# ==============================================================================
# Design Compiler Synthesis Script (synth.tcl)
# Target Frequency: 208MHz (Period: 4.8ns)
# Features: Timing Optimization, Wire Load Model, Gate-Level Netlist Cleanup
# ==============================================================================

# ------------------------------------------------------------------------------
# # 1. 读入 RTL 源代码
# ------------------------------------------------------------------------------
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
# ------------------------------------------------------------------------------
# # 2. 施加时序与物理约束 
# ------------------------------------------------------------------------------
create_clock -name sys_clk -period 5.2 [get_ports clk]  ;# 目标设为 5.2ns (192MHz)
set_ideal_network [get_ports clk]
set_ideal_network [get_ports rst]

set_clock_uncertainty 0.10 [get_clocks sys_clk]

# 输入延迟
set_input_delay 1.0 -clock sys_clk [remove_from_collection [all_inputs] clk]

# 将用于防优化的 dummy 端口声明为 False Path
set_false_path -to [get_ports {RD out_ins}]

# 线负载模型
set_wire_load_mode enclosed
set_wire_load_model -name "wl10" -library "tcbn65lpwc"

# ------------------------------------------------------------------------------
# # 3. 保护例化的两个 SRAM 宏（禁止综合工具尝试优化或拆解 SRAM 内部）
# ------------------------------------------------------------------------------
set_dont_touch [get_cells U_IM/memory]
set_dont_touch [get_cells U_DM/memory]

# ------------------------------------------------------------------------------
# # 4. 优化准备：建立自定义路径组，引导优化策略向关键路径倾斜
# ------------------------------------------------------------------------------
group_path -name sys_clk -weight 10 -critical_range 1.0
group_path -name REGS_TO_REGS -from [all_registers -clock_pins] -to [all_registers -data_pins] -weight 5
group_path -name SRAM_TO_REGS -from [get_cells -hierarchical *memory*] -to [all_registers -data_pins] -weight 5

# 施加合理的设计规则约束，促使工具选用高驱动能力的标准单元
set_max_fanout 30 [current_design]   
set_max_transition 0.4 [current_design]
set_boundary_optimization [get_designs riscv]
set_compile_one2many_structure true

# ------------------------------------------------------------------------------
# # 5. 开启 Formality 形式验证的引导记录
# ------------------------------------------------------------------------------
set_svf ./outputs/riscv.svf

# ------------------------------------------------------------------------------
# # 6. 执行高强度综合编译（带寄存器重定时，以平衡逻辑时序）
# ------------------------------------------------------------------------------
compile_ultra -timing_high_effort_script -retime

# ------------------------------------------------------------------------------
# # 7. 网表净化与命名规范化（解决 VO-4 / VO-11 警告，提高网表质量）
# ------------------------------------------------------------------------------
# 解决 VO-4：消除网表中的 assign 连续赋值语句，使用 Buffer 替代直接连线
set_fix_multiple_port_nets -all -buffer_constants

# 解决 VO-11：规范化网表命名规则，消除悬空端口产生的 SYNOPSYS_UNCONNECTED_ 前缀虚拟网线
change_names -rules verilog -hierarchy

# ------------------------------------------------------------------------------
# # 8. 导出综合成果物 (Verilog 网表, SDC 时序约束, SDF 延迟文件)
# ------------------------------------------------------------------------------
write -format verilog -hierarchy -output ./outputs/riscv_synth.v
write_sdc ./outputs/riscv.sdc
write_sdf ./outputs/riscv.sdf

# ------------------------------------------------------------------------------
# # 9. 导出多维度分析报告
# ------------------------------------------------------------------------------
report_timing -delay_type max -max_paths 10 > ./reports/timing_max.rpt
report_area -hierarchy > ./reports/area.rpt
report_power > ./reports/power.rpt
report_constraint -all_violators > ./reports/violators.rpt

set_svf -off
exit