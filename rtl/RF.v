`include "global_def.v"
`include "ctrl_signal_def.v"

module RF(
    input [4:0] RR1,     // 读取寄存器 1 地址
    input [4:0] RR2,     // 读取寄存器 2 地址
    input [4:0] WR,      // 写入寄存器地址
    input [31:0] WD,     // 写入数据
    input RFWrite,       // 寄存器写使能信号
    input clk,           // 时钟信号
    output [31:0] RD1,   // 读取寄存器 1 数据
    output [31:0] RD2    // 读取寄存器 2 数据
);

    reg [31:0] register [1:31]; // 31 个 32 位寄存器
    reg [31:0] r0 = 32'h0000_0000;

    // 时序写入逻辑（完全保持原设计不变）
    always @(posedge clk) begin
        // 在上升沿时钟信号时，如果写入寄存器地址不为 0 且写使能信号为 1，则写入数据到指定寄存器
        if ((WR != 0) && (RFWrite == 1)) begin
            register[WR] <= WD;
            `ifdef DEBUG
            // 如果定义了 DEBUG 宏，则输出寄存器的值
            $display("R[00-07]=%8X %8X %8X %8X %8X %8X %8X %8X", 0, register[1], register[2], register[3], register[4], register[5], register[6], register[7]);
            $display("R[08-15]=%8X %8X %8X %8X %8X %8X %8X %8X", register[8], register[9], register[10], register[11], register[12], register[13], register[14], register[15]);
            $display("R[16-23]=%8X %8X %8X %8X %8X %8X %8X %8X", register[16], register[17], register[18], register[19], register[20], register[21], register[22], register[23]);
            $display("R[24-31]=%8X %8X %8X %8X %8X %8X %8X %8X", register[24], register[25], register[26], register[27], register[28], register[29], register[30], register[31]);
            `endif
        end
    end

    // 异步读：树状平衡 MUX 结构优化（打散大面积扁平选择器，缩短物理关键路径延时）
    //assign RD1 = (RR1 == 5'd0) ? r0 : register[RR1];
    //assign RD2 = (RR2 == 5'd0) ? r0 : register[RR2];

    // ------------------------------------------------------------------------------
    // 读取通道 1 (RD1) 树状选择器
    // ------------------------------------------------------------------------------
    // 第一级：4 个 8选1 组合选择器（根据 RR1[2:0] 选择）
    wire [31:0] rd1_g0 = (RR1[2:0] == 3'd0) ? r0          :
                         (RR1[2:0] == 3'd1) ? register[1] :
                         (RR1[2:0] == 3'd2) ? register[2] :
                         (RR1[2:0] == 3'd3) ? register[3] :
                         (RR1[2:0] == 3'd4) ? register[4] :
                         (RR1[2:0] == 3'd5) ? register[5] :
                         (RR1[2:0] == 3'd6) ? register[6] : register[7];

    wire [31:0] rd1_g1 = (RR1[2:0] == 3'd0) ? register[8]  :
                         (RR1[2:0] == 3'd1) ? register[9]  :
                         (RR1[2:0] == 3'd2) ? register[10] :
                         (RR1[2:0] == 3'd3) ? register[11] :
                         (RR1[2:0] == 3'd4) ? register[12] :
                         (RR1[2:0] == 3'd5) ? register[13] :
                         (RR1[2:0] == 3'd6) ? register[14] : register[15];

    wire [31:0] rd1_g2 = (RR1[2:0] == 3'd0) ? register[16] :
                         (RR1[2:0] == 3'd1) ? register[17] :
                         (RR1[2:0] == 3'd2) ? register[18] :
                         (RR1[2:0] == 3'd3) ? register[19] :
                         (RR1[2:0] == 3'd4) ? register[20] :
                         (RR1[2:0] == 3'd5) ? register[21] :
                         (RR1[2:0] == 3'd6) ? register[22] : register[23];

    wire [31:0] rd1_g3 = (RR1[2:0] == 3'd0) ? register[24] :
                         (RR1[2:0] == 3'd1) ? register[25] :
                         (RR1[2:0] == 3'd2) ? register[26] :
                         (RR1[2:0] == 3'd3) ? register[27] :
                         (RR1[2:0] == 3'd4) ? register[28] :
                         (RR1[2:0] == 3'd5) ? register[29] :
                         (RR1[2:0] == 3'd6) ? register[30] : register[31];

    // 第二级：1 个 4选1 组合选择器（根据 RR1[4:3] 选择）
    assign RD1 = (RR1[4:3] == 2'b00) ? rd1_g0 :
                 (RR1[4:3] == 2'b01) ? rd1_g1 :
                 (RR1[4:3] == 2'b10) ? rd1_g2 : rd1_g3;


    // ------------------------------------------------------------------------------
    // 读取通道 2 (RD2) 树状选择器
    // ------------------------------------------------------------------------------
    // 第一级：4 个 8选1 组合选择器（根据 RR2[2:0] 选择）
    wire [31:0] rd2_g0 = (RR2[2:0] == 3'd0) ? r0          :
                         (RR2[2:0] == 3'd1) ? register[1] :
                         (RR2[2:0] == 3'd2) ? register[2] :
                         (RR2[2:0] == 3'd3) ? register[3] :
                         (RR2[2:0] == 3'd4) ? register[4] :
                         (RR2[2:0] == 3'd5) ? register[5] :
                         (RR2[2:0] == 3'd6) ? register[6] : register[7];

    wire [31:0] rd2_g1 = (RR2[2:0] == 3'd0) ? register[8]  :
                         (RR2[2:0] == 3'd1) ? register[9]  :
                         (RR2[2:0] == 3'd2) ? register[10] :
                         (RR2[2:0] == 3'd3) ? register[11] :
                         (RR2[2:0] == 3'd4) ? register[12] :
                         (RR2[2:0] == 3'd5) ? register[13] :
                         (RR2[2:0] == 3'd6) ? register[14] : register[15];

    wire [31:0] rd2_g2 = (RR2[2:0] == 3'd0) ? register[16] :
                         (RR2[2:0] == 3'd1) ? register[17] :
                         (RR2[2:0] == 3'd2) ? register[18] :
                         (RR2[2:0] == 3'd3) ? register[19] :
                         (RR2[2:0] == 3'd4) ? register[20] :
                         (RR2[2:0] == 3'd5) ? register[21] :
                         (RR2[2:0] == 3'd6) ? register[22] : register[23];

    wire [31:0] rd2_g3 = (RR2[2:0] == 3'd0) ? register[24] :
                         (RR2[2:0] == 3'd1) ? register[25] :
                         (RR2[2:0] == 3'd2) ? register[26] :
                         (RR2[2:0] == 3'd3) ? register[27] :
                         (RR2[2:0] == 3'd4) ? register[28] :
                         (RR2[2:0] == 3'd5) ? register[29] :
                         (RR2[2:0] == 3'd6) ? register[30] : register[31];

    // 第二级：1 个 4选1 组合选择器（根据 RR2[4:3] 选择）
    assign RD2 = (RR2[4:3] == 2'b00) ? rd2_g0 :
                 (RR2[4:3] == 2'b01) ? rd2_g1 :
                 (RR2[4:3] == 2'b10) ? rd2_g2 : rd2_g3;

endmodule