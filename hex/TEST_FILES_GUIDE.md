# RISC-V CPU 测试文件补全说明

## 📦 文件清单

### 现有测试（12个）✓
已补充汇编源代码注释文件：
- t01_ralu.s + t01_ralu.hex - 寄存器算术逻辑
- t02_itype.s + t02_itype.hex - 立即数指令（符号扩展关键）
- t03_mem.s + t03_mem.hex - 内存读写
- t04_beq_taken.s + t04_beq_taken.hex - BEQ条件满足
- t05_beq_not_taken.s + t05_beq_not_taken.hex - BEQ条件不满足
- t06_bne.s + t06_bne.hex - BNE不等跳转
- t07_jal_link.s + t07_jal_link.hex - JAL链接
- t08_jalr.s + t08_jalr.hex - JALR寄存器跳转
- t09_x0.s + t09_x0.hex - x0恒零寄存器
- t10_loop_bne.s + t10_loop_bne.hex - 循环跳转
- t11_jal_back.s + t11_jal_back.hex - JAL向后跳转
- t12_sw_neg.s + t12_sw_neg.hex - 负偏移存储

### 新增测试（4个）✨
已补充汇编源代码和机器码：

#### 优先级1 - 关键缺陷修复
- **t13_shift_boundary.s + t13_shift_boundary.hex** - 移位量0/31边界值测试
  * 验证sll, srl, sra在极端移位量下的正确性
  * 确保移位量=0时返回原值，移位量=31时正确处理符号位

- **t14_add_negative.s + t14_add_negative.hex** - 算术指令负数组合
  * 测试 负+负=负、负+正、正-负 等各种符号组合
  * 验证加法/减法器的正确性

#### 优先级2 - 完整性补充
- **t15_bne_false.s + t15_bne_false.hex** - BNE条件不满足测试
  * 补充BNE的反向条件（条件相等时不跳转）
  * 完善分支指令测试覆盖

#### 优先级3 - 可选深化
- **t16_lw_negative_extend.s + t16_lw_negative_extend.hex** - 负偏移读取深化
  * 测试更多负偏移大小的组合
  * 验证地址计算在边界条件下的表现

---

## 📝 文件格式说明

### .s 文件（汇编源代码）
- **格式**: RISC-V汇编
- **注释**: 使用 `#` 号开头
- **用途**: 
  - 在指令集模拟器中查看和理解指令语义
  - 作为.hex文件的可读参考
  - 便于调试和验证指令功能

**示例**:
```asm
# t02_itype.s - Immediate Type Instructions Test
addi x1, x0, -1       # x1 = 0xFFFFFFFF (符号扩展测试!)
addi x2, x1, 1        # x2 = 0 (负+正=0)
```

### .hex 文件（机器码）
- **格式**: 十六进制32位指令，每行一条
- **用途**: 
  - 直接加载到CPU的指令存储器
  - 由模拟器/仿真器执行
  - 验证硬件的机器码执行能力

**示例**:
```
FFF00093    # addi x1, x0, -1
00108113    # addi x2, x1, 1
```

### ✨ 取消 .golden 文件
**理由**: 
- 只需查看寄存器最终值，不需要自动化对比
- 在模拟器中可直接观察各寄存器内容
- 减少文件冗余

---

## 🚀 使用流程

### 1. 在指令集模拟器中的使用

#### 步骤1: 打开.s文件查看指令语义
```
编辑器中打开 → 查看带#注释的汇编代码 → 理解每条指令的功能
```

#### 步骤2: 加载.hex文件到模拟器
```
指令集模拟器 → Load Instructions → 选择 .hex 文件 → 执行
```

#### 步骤3: 检查结果
```
运行仿真 → 查看各寄存器最终值 → 与预期结果对比
预期结果可从 .s 文件的注释中获取
```

### 2. 编译和验证流程（可选）

如果需要自己验证hex编码的正确性：

```bash
# 使用RISC-V工具链编译
riscv32-unknown-elf-as -o test13.o t13_shift_boundary.s
riscv32-unknown-elf-objcopy -O binary test13.o test13.bin

# 转换为hex格式
hexdump -C test13.bin > test13_generated.hex

# 对比生成的hex与提供的hex是否一致
diff t13_shift_boundary.hex test13_generated.hex
```

---

## 📊 测试覆盖检查表

### 运行所有16个测试后，检查以下内容：

#### 关键功能验证 ✓
- [ ] 符号扩展: addi x1, x0, -1 → x1 = 0xFFFFFFFF
- [ ] x0恒零: 任何写入x0都不生效
- [ ] 负偏移地址计算: ALU正确处理基址+负立即数
- [ ] 分支跳转: beq/bne 条件满足/不满足都正确
- [ ] JAL/JALR: 无条件跳转和返回地址保存

#### 边界值覆盖 ⭐ (新增)
- [ ] sll/srl/sra 移位量=0时返回原值
- [ ] sll/srl/sra 移位量=31时正确处理
- [ ] sra 负数右移补1: 0xFFFFFFFF >> 31 = 0xFFFFFFFF
- [ ] sra 正数右移补0: 0x7FFF >> 31 = 0x00000000
- [ ] add 负+负 = 负结果
- [ ] sub 负-正 = 负结果
- [ ] BNE 相等时不跳转（条件反向）

#### 指令完整性
- [ ] R-type (add, sub, and, or, xor, sll, srl, sra): t01 ✓
- [ ] I-type (addi, ori): t02 ✓
- [ ] Load (lw): t03, t12, t16
- [ ] Store (sw): t03, t12
- [ ] Branch (beq, bne): t04, t05, t06, t10
- [ ] Jump (jal, jalr): t07, t08, t11

---

## 📈 验证预期结果

### t13_shift_boundary 预期寄存器值
```
x1 = 0x00000001    # 初始值
x2 = 0xFFFFFFFF    # -1
x4 = 0x00007FFF    # 正数
x5 = 0x0000001F    # 31 (移位量)
x8 = 0x00000001    # 1 << 0
x9 = 0x80000000    # 1 << 31
x10 = 0x00000001   # 1 >> 0
x11 = 0x00000001   # 0xFFFFFFFF >> 31 (逻辑移位)
x12 = 0x00000001   # 1 >> 0
x13 = 0xFFFFFFFF   # 0xFFFFFFFF >> 31 (算术移位，补1)
x14 = 0x00000000   # 0x7FFF >> 31 (算术移位，补0)
```

### t14_add_negative 预期寄存器值
```
x1 = 0xFFFFFFFF    # -1
x2 = 0xFFFFFFFE    # -2
x8 = 0xFFFFFFFD    # (-1) + (-2) = -3
x9 = 0x00000004    # (-1) + 5 = 4
x10 = 0xFFFFFFFA   # (-1) - 5 = -6
x11 = 0xFFFFFFFF   # (-2) - (-1) = -1
x12 = 0x00000011   # 16 - (-1) = 17
x13 = 0x00000000   # (-1) + 1 = 0
```

### t15_bne_false 预期寄存器值
```
x1 = 0x00000055
x2 = 0x00000055
x5 = 0x000000AA    # BNE不跳转，该指令执行
x6 = 0x00000011    # BNE不跳转，继续执行
x7 = 0x00000077    # 第二个BNE也不跳转
x8 = 0x00000088    # 继续执行
```

---

## 🔧 故障排除

### 问题1: hex文件加载失败
**原因**: 格式不兼容或编码错误
**解决**: 
- 检查.hex文件中每行是否恰好8个十六进制字符
- 确保使用小端格式（如果模拟器要求）
- 使用hexdump或二进制查看器验证

### 问题2: 模拟器显示错误结果
**原因**: 可能是硬件实现bug或hex编码错误
**调试步骤**:
1. 查看.s汇编文件中的预期行为
2. 逐步执行，观察中间寄存器值
3. 对比与.s文件注释的预期结果
4. 若差异，检查对应硬件模块（ALU, 内存等）

### 问题3: 不确定hex是否正确
**方法**: 
- 用工具链重新编译.s文件
- 对比生成的hex与提供的hex
- 若不一致，参考工具链生成的版本

---

## 📚 补充资源

### RISC-V指令编码参考
- R-type (add, sub, sll, srl, sra, and, or, xor):
  ```
  [31:25]funct7 | [24:20]rs2 | [19:15]rs1 | [14:12]funct3 | [11:7]rd | [6:0]opcode(0x33)
  ```

- I-type (addi, ori, lw, jalr):
  ```
  [31:20]imm[11:0] | [19:15]rs1 | [14:12]funct3 | [11:7]rd | [6:0]opcode
  ```

- S-type (sw, sh, sb):
  ```
  [31:25]imm[11:5] | [24:20]rs2 | [19:15]rs1 | [14:12]funct3 | [11:7]imm[4:0] | [6:0]opcode(0x23)
  ```

- B-type (beq, bne, blt, bge, bltu, bgeu):
  ```
  [31:25]imm[12|10:5] | [24:20]rs2 | [19:15]rs1 | [14:12]funct3 | [11:7]imm[4:1|11] | [6:0]opcode(0x63)
  ```

- J-type (jal):
  ```
  [31:20]imm[20|10:1|11|19:12] | [11:7]rd | [6:0]opcode(0x6F)
  ```

---

## ✅ 最终清单

完整的16个测试套件：
```
✓ t01_ralu.s + t01_ralu.hex
✓ t02_itype.s + t02_itype.hex
✓ t03_mem.s + t03_mem.hex
✓ t04_beq_taken.s + t04_beq_taken.hex
✓ t05_beq_not_taken.s + t05_beq_not_taken.hex
✓ t06_bne.s + t06_bne.hex
✓ t07_jal_link.s + t07_jal_link.hex
✓ t08_jalr.s + t08_jalr.hex
✓ t09_x0.s + t09_x0.hex
✓ t10_loop_bne.s + t10_loop_bne.hex
✓ t11_jal_back.s + t11_jal_back.hex
✓ t12_sw_neg.s + t12_sw_neg.hex
✨ t13_shift_boundary.s + t13_shift_boundary.hex (新增)
✨ t14_add_negative.s + t14_add_negative.hex (新增)
✨ t15_bne_false.s + t15_bne_false.hex (新增)
✨ t16_lw_negative_extend.s + t16_lw_negative_extend.hex (新增)
```

**总计**: 32个文件（16个.s源代码 + 16个.hex机器码）

---

## 🎯 后续行动

1. **立即**: 在模拟器中运行t13-t15，验证边界值覆盖
2. **次要**: 若测试失败，根据预期结果调试硬件
3. **可选**: 运行t16进行额外深化测试
4. **存档**: 保存所有通过的测试作为回归测试套件
