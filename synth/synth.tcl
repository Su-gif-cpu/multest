# ==============================================================================
# Design Compiler 综合脚本 (synth.tcl)
# 目标工艺: TSMC 65 nm, 目标频率: 200 MHz (时钟周期 5.000 ns)
# ==============================================================================

# 辅助函数：确保时序约束所需的关键网表节点或单元确实存在
# 若节点缺失（如名字拼错），脚本将立即报错退出，防止因无约束综合而导致不良芯片
proc require_collection {description collection} {
    if {[sizeof_collection $collection] == 0} {
        echo "ERROR: required collection is empty: $description"
        exit 2
    }
}

# ------------------------------------------------------------------------------
# 1. 读入并解析 RTL 源代码
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
uniquify

# ------------------------------------------------------------------------------
# 2. 获取并校验关键的时序节点（供后续设置时序例外和路径组使用）
# ------------------------------------------------------------------------------
set im_memory    [get_cells U_IM/memory]
set dm_memory    [get_cells U_DM/memory]
set im_q_pins    [get_pins U_IM/memory/Q*]
set dm_addr_pins [get_pins U_DM/memory/A*]
set rf_rd2_pins  [get_pins U_RF/RD2*]
set npc_rs_pins  [get_pins U_NPC/rs*]

require_collection "U_IM/memory"       $im_memory
require_collection "U_DM/memory"       $dm_memory
require_collection "U_IM/memory/Q[*]"  $im_q_pins
require_collection "U_DM/memory/A[*]"  $dm_addr_pins
require_collection "U_RF/RD2[*]"       $rf_rd2_pins
require_collection "U_NPC/rs[*]"       $npc_rs_pins

# ------------------------------------------------------------------------------
# 3. 核心时钟与 I/O 延迟约束
# ------------------------------------------------------------------------------
# 创建 200 MHz 主时钟
create_clock -name sys_clk -period 5.000 [get_ports clk]
set_ideal_network [get_ports clk]
set_ideal_network [get_ports rst]

# 设置时钟不确定度（Setup 100ps 模拟抖动与偏差，Hold 50ps 为后续时钟树综合预留安全量）
set_clock_uncertainty -setup 0.10 [get_clocks sys_clk]
set_clock_uncertainty -hold  0.05 [get_clocks sys_clk]
set_clock_transition 0.08 [get_clocks sys_clk]

# rst 为异步复位信号，将其设为虚假路径（False Path），切断时序检查
set_false_path -from [get_ports rst]
# 本CPU核除时钟（clk）和异步复位（rst）外无其他同步输入端口，故无需设置 input_delay

# 约束外部同步输出端口 RD（数据总线）和 out_ins（指令总线）
# 将输出延迟（Output Delay）设为 2.500ns（占周期的 50%），为外部板级布线/外设预留充足时间
set_output_delay -clock sys_clk -max 2.500 [get_ports {RD out_ins}]
set_output_delay -clock sys_clk -min -0.200 [get_ports {RD out_ins}]

# 设置输出端口负载电容，模拟真实的物理引脚负载（50fF）
set_load -pin_load 0.05 [get_ports {RD out_ins}]

# 强制应用线负载模型（WLM）
# 采用包容模式（enclosed）并强制加载 tcbn65lpwc 库中的 wl10 模型。若加载失败则报错退出，拒绝使用零负载。
set_wire_load_mode enclosed
if {[catch {set_wire_load_model -name "wl10" -library "tcbn65lpwc"} wireload_error]} {
    echo "ERROR: Failed to apply wire load model tcbn65lpwc/wl10: $wireload_error"
    exit 2
}

# ------------------------------------------------------------------------------
# 4. 逻辑论证通过的模式排他性虚假路径 (False Paths)
# ------------------------------------------------------------------------------
# 虚假路径 1: RD2 -> 数据存储器（DM）地址端。
# 原因：当数据 SRAM 读写有效时，ALU 的 B 操作数在 SW 时选 Offset，在 LW 时选 Imm。
# 在这两种工作模式下，RD2 的值都不可能作为形成 DM 物理地址的计算源。
set_false_path -through $rf_rd2_pins -to $dm_addr_pins

# 虚假路径 2: RD2 -> NPC 跳转目标 rs 端。
# 原因：NPC 仅在 JALR 指令时选择 rs 寄存器的值作为基址（此时 ALU-B 选择的是 Imm 立即数）。
# 分支指令虽然用到 RD2 进行大小比较，但跳转计算使用的是 PC+Offset，而非选择 NPC.rs。
set_false_path -through $rf_rd2_pins -through $npc_rs_pins

# ------------------------------------------------------------------------------
# 5. SRAM 保护、层级展平控制与路径组权重
# ------------------------------------------------------------------------------
# 保护 SRAM 宏单元（禁止综合工具拆解或修改内部结构）
set_dont_touch [add_to_collection $im_memory $dm_memory]

# 允许对除存储器、寄存器堆以外的子模块做跨边界优化（Boundary Optimization）
set_boundary_optimization [get_designs -hierarchical *] true

# 将无状态、纯组合逻辑的多路选择器和译码器打散（Ungroup），最大化时序收敛空间
# 同时保留了 RF、PC 等重要时序模块的层级结构，极大地便利了后端的物理布局规划（Floorplan）
set_ungroup [get_designs {MUX_2to1_A MUX_3to1_B MUX_3to1 MUX_3to1_LMD EXT ControlUnit ALU}] true

# 获取 PC 和寄存器堆的时序数据输入端（D端），用于自定义路径组
# 使用 all_registers -data_pins 配合 filter_collection，避开工艺库引脚命名不一致的问题
set pc_d_pins [filter_collection [all_registers -data_pins] "full_name =~ U_PC/*"]
set rf_d_pins [filter_collection [all_registers -data_pins] "full_name =~ U_RF/*"]

require_collection "U_PC 寄存器数据端" $pc_d_pins
require_collection "U_RF 寄存器堆数据端" $rf_d_pins

# 建立自定义路径组，对 IM（指令SRAM）读出相关的关键路径赋予更高的优化权重
group_path -name IM_TO_PC -from $im_q_pins -to $pc_d_pins   -weight 30 -critical_range 1.00
group_path -name IM_TO_RF -from $im_q_pins -to $rf_d_pins   -weight 25 -critical_range 1.00
group_path -name IM_TO_DM -from $im_q_pins -to $dm_addr_pins -weight 30 -critical_range 1.00
group_path -name REG_TO_REG -from [all_registers -clock_pins] -to [all_registers -data_pins] -weight 10 -critical_range 0.80

# 设定设计规则约束 (DRC)
set_max_fanout 20 [current_design]
set_max_transition 0.25 [current_design]
set_compile_one2many_structure true

# 清除默认的功耗约束，避免综合工具产生假的时序违例
catch {remove_attribute [current_design] max_leakage_power}
catch {remove_attribute [current_design] max_dynamic_power}
catch {remove_attribute [current_design] max_total_power}

# ------------------------------------------------------------------------------
# 6. 高强度时序综合（Compile）
# ------------------------------------------------------------------------------
# 记录形式验证所需的 SVF 文件
set_svf ./outputs/riscv.svf

# 修复多端口网络（必须在第一次 compile 前执行以正确插入 buffer）
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

# 第一阶段综合：开启高强度时序优化策略，并启用寄存器重定位（Register Retiming）以平衡流水线
compile_ultra -timing_high_effort_script -retime

# 结构优化后再次修复多端口网络，防止因单元拆解产生新的 feedthrough 违例
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

# 第二阶段综合：增量编译，做最后的时序冲刺
compile_ultra -incremental -timing_high_effort_script

# ------------------------------------------------------------------------------
# 7. 写出网表及后端布局布线（P&R）所需的时序约束（SDC/SDF）
# ------------------------------------------------------------------------------
# 净化网表命名规则，确保符合 Verilog 规范，防止 P&R 阶段读入网表出错
change_names -rules verilog -hierarchy

write -format verilog -hierarchy -output ./outputs/riscv_synth.v
write_sdc ./outputs/riscv.sdc
write_sdf ./outputs/riscv.sdf

# ------------------------------------------------------------------------------
# 8. 生成供后端审计和前端 Sign-off 的分析报告
# ------------------------------------------------------------------------------
report_qor > ./reports/qor.rpt
report_design > ./reports/design.rpt
check_timing -verbose > ./reports/check_timing.rpt

# 建立与保持时间时序报告
report_timing -delay_type max -max_paths 50 -nworst 3 -input_pins -nets \
    > ./reports/timing_setup.rpt
report_timing -delay_type min -max_paths 50 -nworst 3 -input_pins -nets \
    > ./reports/timing_hold.rpt

# 针对 IM 读出关键路径的定向审计报告
report_timing -delay_type max -from $im_q_pins -to $pc_d_pins -max_paths 20 -nworst 3 -input_pins -nets \
    > ./reports/timing_im_to_pc.rpt
report_timing -delay_type max -from $im_q_pins -to $rf_d_pins -max_paths 20 -nworst 3 -input_pins -nets \
    > ./reports/timing_im_to_rf.rpt
report_timing -delay_type max -from $im_q_pins -to $dm_addr_pins -max_paths 20 -nworst 3 -input_pins -nets \
    > ./reports/timing_im_to_dm.rpt

# 时序例外与全局冲突违例报告
report_exceptions -verbose > ./reports/exceptions.rpt
report_constraint -all_violators > ./reports/violators.rpt

# 专门生成 DRC 违例报告，确保 max_transition/max_fanout 在物理实现前满足工艺库规范
report_constraint -all_violators -max_transition -max_fanout -max_capacitance \
    > ./reports/design_rule_violators.rpt

# 面积与功耗估算报告
report_area -hierarchy > ./reports/area.rpt
report_power > ./reports/power.rpt

# 在终端直接输出时序结果总结，便于设计师一目了然地确认 WNS (Worst Negative Slack) 状态
echo "========== 200 MHz 综合时序 QoR 总结 =========="
report_qor
echo "================================================"

set_svf -off
exit