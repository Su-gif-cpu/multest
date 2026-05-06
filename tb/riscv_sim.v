`timescale 1ns / 1ps

module riscv_sim ();
    // ========================================================
    // 配置参数
    // ========================================================
    parameter PC_BASE = 32'h00002000; // CPU 起始运行地址
    parameter END_PC  = 32'h000000B4; // 结束死循环的相对偏移地址

    // Inputs
    reg clk;
    reg rst;
    integer i;

    // Instantiate the DUT (Device Under Test)
    riscv U_RISCV(
        .clk(clk), 
        .rst(rst)
    );

    // ========================================================
    // 初始化与复位
    // ========================================================
    initial begin
        // 初始化寄存器堆 (Register File)
        for (i = 1; i < 32; i = i + 1) begin
            U_RISCV.U_RF.register[i] = 32'h0;
        end

        // 初始化数据存储器 (Data Memory)
        for (i = 0; i < 1024; i = i + 1) begin
            U_RISCV.U_DM.memory[i] = 32'h0;
        end
        
        // 载入正确的 Hex 机器码到指令存储器
        // 注意：如果 hex 文件中带有 @2000 标识，请确保 U_IM 模块能正确处理基地址映射
        $readmemh("../hex/code.hex", U_RISCV.U_IM.memory);  
        
        $display("\n[INIT] Instruction memory initialized.");
        $display("[INIT] CPU PC starts at 0x%08X\n", PC_BASE);
        
        // 监控核心运行状态
        $monitor("Time: %0t | PC = 0x%08X | IR = 0x%08X", $time, U_RISCV.U_PC.PC, U_RISCV.out_ins);
        
        // 产生复位信号
        clk = 1;
        #5;       
        rst = 1;
        #20;      
        rst = 0;
    end

    // 时钟生成 (周期为 100ns)
    always #50 clk = ~clk;

    // ========================================================
    // 性能统计与错误标志
    // ========================================================
    integer total_cycles = 0;   // 总运行时钟周期
    integer total_instrs = 0;   // 总执行指令数
    real    ipc_value    = 0.0; // IPC 浮点结果

    reg test_failed_beq       = 0;
    reg test_failed_jalr_skip = 0;
    
    // 超时保险 (Watchdog)
    initial begin
        #1000000; 
        $display("\n=============================================");
        $display("  [TIMEOUT] Simulation Timeout! ");
        if (total_cycles > 0) ipc_value = $itor(total_instrs) / $itor(total_cycles);
        $display("  Current IPC        : %0.3f", ipc_value);
        $display("  Current PC         : 0x%08X", U_RISCV.U_PC.PC);
        $display("=============================================\n");
        $finish;
    end

    // ========================================================
    // 运行监控与结果判定逻辑
    // ========================================================
    always @(posedge clk) begin
        if (rst == 0) begin
            // 统计周期与指令数 (假设 PCWrite 高电平代表指令完成，适用于多周期 CPU)
            total_cycles = total_cycles + 1;
            if (U_RISCV.PCWrite == 1'b1) begin
                total_instrs = total_instrs + 1;
            end

            // 监控 1：判断 BEQ 跳转是否失败（PC 是否掉入了本该跳过的 0x88 区域）
            if (U_RISCV.U_PC.PC == (PC_BASE + 32'h00000088)) begin
                test_failed_beq = 1;
            end
            
            // 监控 2：判断 JALR 跳过逻辑是否失败（PC 是否掉入了本该跳过的 0xA8/0xAC 区域）
            if (U_RISCV.U_PC.PC == (PC_BASE + 32'h000000A8) || 
                U_RISCV.U_PC.PC == (PC_BASE + 32'h000000AC)) begin
                test_failed_jalr_skip = 1;
            end
            
            // 监控 3：到达程序的最后一条原地死循环指令 (偏移 END_PC)
            if (U_RISCV.U_PC.PC == (PC_BASE + END_PC)) begin
                ipc_value = $itor(total_instrs) / $itor(total_cycles); 
                
                // 联合判断所有寄存器预期结果 (结合你的 C 代码逻辑)
                if (U_RISCV.U_RF.register[30] == 32'h000000AB &&                        // 访存验证点
                    U_RISCV.U_RF.register[3]  == 32'h000000C0 &&                        // ALU/BNE循环验证点 (192)
                    U_RISCV.U_RF.register[2]  == 32'h000000C0 &&                        // ALU/BNE循环验证点 (192)
                    U_RISCV.U_RF.register[8]  == (PC_BASE + 32'h000000A8) &&            // JALR Link 地址
                    U_RISCV.U_RF.register[9]  == (PC_BASE + 32'h000000A8) &&            // JALR 目标地址
                    U_RISCV.U_RF.register[10] == 32'h00000000 &&                        // JALR 跨域指令未执行验证
                    test_failed_beq == 0 && 
                    test_failed_jalr_skip == 0) 
                begin
                    $display("\n=============================================");
                    $display("  [SUCCESS] All Instructions Passed! ");
                    $display("  [v] x30 == 0xAB       (Load/Store & Branch OK)");
                    $display("  [v] x3  == 0xC0       (ALU & BNE Loop OK)");
                    $display("  [v] x8  == 0x%08X (JALR Link Address OK)", (PC_BASE + 32'h000000A8));
                    $display("  [v] x9  == 0x%08X (JALR Target Jump OK)", (PC_BASE + 32'h000000A8));
                    $display("  [v] x10 == 0x00000000 (JALR Skip Logic OK)");
                    $display("  ---------------------------------------------");
                    $display("  Final PC           : 0x%08X", U_RISCV.U_PC.PC);
                    $display("  Total Cycles       : %0d", total_cycles);
                    $display("  Total Instructions : %0d", total_instrs);
                    $display("  Final IPC          : %0.3f", ipc_value);
                    $display("=============================================\n");
                end else begin
                    $display("\n=============================================");
                    $display("  [FAILED] Simulation Failed at the End! ");
                    
                    if (test_failed_beq) 
                        $display("  Reason: Branch 'beq' failed. PC hit forbidden offset 0x88.");
                    else if (test_failed_jalr_skip)
                        $display("  Reason: JALR jump failed. PC hit skipped instructions at offset 0xA8/0xAC.");
                    else begin
                        $display("  Reason: Final Register values are wrong.");
                        $display("  Expected:");
                        $display("    x30 = 0x000000AB");
                        $display("    x3  = 0x000000C0 (192)");
                        $display("    x8  = 0x%08X", (PC_BASE + 32'h000000A8));
                        $display("    x10 = 0x00000000");
                        $display("  Actual:");
                        $display("    x30 = 0x%08X", U_RISCV.U_RF.register[30]);
                        $display("    x3  = 0x%08X", U_RISCV.U_RF.register[3]);
                        $display("    x8  = 0x%08X", U_RISCV.U_RF.register[8]);
                        $display("    x10 = 0x%08X", U_RISCV.U_RF.register[10]);
                    end
                    $display("  ---------------------------------------------");
                    $display("  Final IPC          : %0.3f", ipc_value);
                    $display("=============================================\n");
                end
                
                $finish; // 结束仿真
            end
        end
    end

    // ========================================================
    // 波形导出 (Verdi FSDB)
    // ========================================================
    initial begin
        $fsdbDumpvars(0, "riscv_sim"); 
        $fsdbDumpMDA(0, "riscv_sim");  // 导出数组(如寄存器堆、内存)，方便抓波形
    end

endmodule