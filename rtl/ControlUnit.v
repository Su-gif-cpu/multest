`include "ctrl_signal_def.v"
`include "instruction_def.v"

// 时序闭合要点（IPC = 0.498，与原 3 状态一致）：
// 1. IR 真正锁存，切断 IM.Q->译码->ALU->PC 超长组合路径
// 2. 同步 SRAM：EX 用 NPC 预取；IF 再 IRWrite（不能同拍改地址又锁 IR）
// 3. 非 LW：IF+EX = 2 拍；LW：IF+EX+WB = 3 拍（WB 后回 IF，不跳过取指）
module ControlUnit(
    input clk, rst, zero,
    input [6:0] opcode,
    input [6:0] Funct7,
    input [2:0] Funct3,
    output reg PCWrite, InsMemRW, IRWrite, RFWrite, ExtSel, ALUSrcA,
    output reg IM_UseNPC,
    output reg [1:0] DMCtrl, 
    output reg [1:0] ALUSrcB, RegSel, NPCOp, WDSel,
    output reg [3:0] ALUOp
);

    localparam S_IF_BOOT = 2'd0;
    localparam S_IF      = 2'd1;
    localparam S_EX      = 2'd2;
    localparam S_WB      = 2'd3;

    reg [1:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) state <= S_IF_BOOT;
        else     state <= next_state;
    end

    always @(*) begin
        case (state)
            S_IF_BOOT: next_state = S_IF;
            S_IF:      next_state = S_EX;
            S_EX:      next_state = (opcode == `INSTR_LW_OP) ? S_WB : S_IF;
            S_WB:      next_state = S_IF; // 与原设计一致：LW 后仍走取指，IPC 回到 0.498
            default:   next_state = S_IF_BOOT;
        endcase
    end

    always @(*) begin
        PCWrite   = 0;
        InsMemRW  = 0;
        IRWrite   = 0;
        RFWrite   = 0;
        IM_UseNPC = 0;
        DMCtrl    = 2'b00;
        ExtSel    = `ExtSel_SIGNED;
        ALUSrcA   = `ALUSrcA_A;
        ALUSrcB   = `ALUSrcB_B;
        RegSel    = `RegSel_rd;
        NPCOp     = `NPC_PC;
        WDSel     = `WDSel_FromALU;
        ALUOp     = `ALUOp_ADD;

        case (state)
            S_IF_BOOT: begin
                InsMemRW  = 1;
                IM_UseNPC = 0; // 地址 = PC
            end
            S_IF: begin
                InsMemRW  = 1;
                IM_UseNPC = 0;
                IRWrite   = 1; // 锁存上一拍预取得到的 Q
            end
            S_EX: begin
                InsMemRW  = 1;
                IM_UseNPC = 1; // 预取 NPC，供下一拍 IF 锁存
                case (opcode)
                    `INSTR_RTYPE_OP: begin
                        ALUSrcA = `ALUSrcA_A;
                        ALUSrcB = `ALUSrcB_B;
                        case ({Funct7, Funct3})
                            `INSTR_ADD_FUNCT: ALUOp = `ALUOp_ADD;
                            `INSTR_SUB_FUNCT: ALUOp = `ALUOp_SUB;
                            `INSTR_AND_FUNCT: ALUOp = `ALUOp_AND;
                            `INSTR_OR_FUNCT:  ALUOp = `ALUOp_OR;
                            `INSTR_XOR_FUNCT: ALUOp = `ALUOp_XOR;
                            `INSTR_SLL_FUNCT: ALUOp = `ALUOp_SLL;
                            `INSTR_SRL_FUNCT: ALUOp = `ALUOp_SRL;
                            `INSTR_SRA_FUNCT: ALUOp = `ALUOp_SRA;
                        endcase
                        RFWrite = 1;
                        PCWrite = 1;
                    end
                    `INSTR_ITYPE_OP: begin
                        ALUSrcA = `ALUSrcA_A;
                        ALUSrcB = `ALUSrcB_Imm;
                        ExtSel  = `ExtSel_SIGNED;
                        if (Funct3 == `INSTR_ORI_FUNCT) ALUOp = `ALUOp_OR;
                        else ALUOp = `ALUOp_ADD;
                        RFWrite = 1;
                        PCWrite = 1;
                    end
                    `INSTR_SW_OP: begin
                        ALUSrcA = `ALUSrcA_A;
                        ALUSrcB = `ALUSrcB_Offset;
                        ALUOp   = `ALUOp_ADD;
                        DMCtrl  = 2'b10;
                        PCWrite = 1;
                    end
                    `INSTR_LW_OP: begin
                        ALUSrcA = `ALUSrcA_A;
                        ALUSrcB = `ALUSrcB_Imm;
                        ALUOp   = `ALUOp_ADD;
                        DMCtrl  = 2'b01;
                        // 预取 PC+4，WB 继续挂地址，随后 IF 再 IRWrite
                    end
                    `INSTR_BTYPE_OP: begin
                        ALUSrcA = `ALUSrcA_A;
                        ALUSrcB = `ALUSrcB_B;
                        ALUOp   = `ALUOp_SUB;
                        PCWrite = 1;
                        if ((Funct3 == `INSTR_BEQ_FUNCT && zero) ||
                            (Funct3 == `INSTR_BNE_FUNCT && !zero))
                            NPCOp = `NPC_Offset12;
                        else
                            NPCOp = `NPC_PC;
                    end
                    `INSTR_JAL_OP: begin
                        PCWrite = 1;
                        NPCOp   = `NPC_Offset20;
                        RFWrite = 1;
                        WDSel   = `WDSel_FromPC;
                    end
                    `INSTR_JALR_OP: begin
                        ALUSrcA = `ALUSrcA_A;
                        ALUSrcB = `ALUSrcB_Imm;
                        ALUOp   = `ALUOp_ADD;
                        PCWrite = 1;
                        NPCOp   = `NPC_rs;
                        RFWrite = 1;
                        WDSel   = `WDSel_FromPC;
                    end
                endcase
            end
            S_WB: begin
                // 写回 RF/PC；IM 继续挂 NPC(=PC+4)，本拍不锁 IR
                // 下一拍 S_IF 再 IRWrite，节拍与原 FETCH→EXEC→WB→FETCH 一致
                PCWrite   = 1;
                RFWrite   = 1;
                WDSel     = `WDSel_FromMEM;
                InsMemRW  = 1;
                IM_UseNPC = 1;
                IRWrite   = 0;
            end
        endcase
    end
endmodule
