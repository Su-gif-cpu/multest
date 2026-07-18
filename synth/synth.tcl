# ==============================================================================
# Design Compiler Synthesis Script (synth.tcl)
# ==============================================================================

# 1. 读入 RTL 源代码
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

# 2. 施加时序与物理约束 
create_clock -name sys_clk -period 5.6 [get_ports clk]  
set_ideal_network [get_ports clk]
set_ideal_network [get_ports rst]

set_clock_uncertainty 0.10 [get_clocks sys_clk]

# 输入延迟设置
set_input_delay 0.8 -clock sys_clk [remove_from_collection [all_inputs] clk]
set_false_path -to [get_ports {RD out_ins}]

# 基于编译前层级关系设置的虚假路径约束（DC 在后续 compile 中会自动将约束映射到打散后的网表上）
# 约束 1：屏蔽经过 RD2 端口到数据存储器地址端的时序路径
set_false_path -through [get_pins U_RF/RD2*] -to [get_cells U_DM/memory]

# 约束 2：屏蔽经过 RD2 端口到 NPC 跳转目标地址端的时序路径
set_false_path -through [get_pins U_RF/RD2*] -to [get_pins U_NPC/rs*]

# 线负载模型
set_wire_load_mode enclosed
set_wire_load_model -name "wl10" -library "tcbn65lpwc"

# 3. 保护 SRAM 宏单元 (禁止拆解内部)
set_dont_touch [get_cells U_IM/memory]
set_dont_touch [get_cells U_DM/memory]

# 4. 边界优化与跨模块打散（Ungrouping）策略
# 允许所有子模块做边界优化
set_boundary_optimization [get_designs -hierarchical *]

# 仅自动打散除 NPC 以外的纯组合逻辑模块，以保护 NPC 端口层级，确保 SDC 约束正确挂载
set_ungroup [get_designs {MUX_2to1_A MUX_3to1_B MUX_3to1 MUX_3to1_LMD EXT ControlUnit ALU}] true

# 5. 路径组权重与设计规则约束
# 将 SRAM 读出路径设为最高优先级
group_path -name sys_clk -weight 10 -critical_range 0.8
group_path -name REGS_TO_REGS -from [all_registers -clock_pins] -to [all_registers -data_pins] -weight 5
group_path -name SRAM_TO_REGS -from [get_cells -hierarchical *memory*] -to [all_registers -data_pins] -weight 20

# 强制工具采用高驱动单元，加速转换沿
set_max_fanout 20 [current_design]   
set_max_transition 0.25 [current_design]
# 声明多端口网络修复属性（编译前生效）
set_fix_multiple_port_nets -all -buffer_constants
set_compile_one2many_structure true

# 6. Formality 记录与高强度编译
set_svf ./outputs/riscv.svf

# 阶段一：带 Register Retiming 的高强度首次编译
compile_ultra -timing_high_effort_script -retime

# 阶段二：针对 Timing 瓶颈的增量二次编译
compile_ultra -incremental

# 7. 网表净化与命名规范化
change_names -rules verilog -hierarchy

# 8. 导出成果物与分析报告
write -format verilog -hierarchy -output ./outputs/riscv_synth.v
write_sdc ./outputs/riscv.sdc
write_sdf ./outputs/riscv.sdf

report_timing -delay_type max -max_paths 10 > ./reports/timing_max.rpt
report_area -hierarchy > ./reports/area.rpt
report_power > ./reports/power.rpt
report_constraint -all_violators > ./reports/violators.rpt

set_svf -off
exit