`timescale 1ns / 1ps
`include "ctrl_signal_def.v"

module IM(InsMemRW, addr, clk, Ins);
    input               InsMemRW;
    input       [11:2]  addr;
    input               clk;
    output      [31:0]  Ins;

    wire [10:0] sram_addr = {1'b0, addr};
    wire [63:0] sram_dout;

    // 例化 SRAM 宏 
    TS1N65LPLL2048X64M8 memory (
        .A   (sram_addr),
        .D   (64'b0),
        .Q   (sram_dout),
        .CLK (clk),                      
        .CEB (1'b0),                     
        .WEB (1'b1),                     
        .BWEB(64'hFFFFFFFF_FFFFFFFF),    
        .TSEL(2'b01)
    );

    assign Ins = sram_dout[31:0];

    // 实时打印调试
    always @(posedge clk) begin
        #2; 
        $display("[IM_DEBUG] Time: %0t | PC_addr_in: %0d | SRAM_A: %0d | SRAM_Q: %h | Ins_out: %h", 
                 $time, addr, sram_addr, sram_dout, Ins);
    end

endmodule