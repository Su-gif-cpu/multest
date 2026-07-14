`timescale 1ns / 1ps
`include "ctrl_signal_def.v"

module DM( Addr, Addr_bypass, WD, WD_bypass, clk, DMCtrl, RD);
    input [11:2] Addr;
    input [11:2] Addr_bypass;
    input [31:0] WD;
    input [31:0] WD_bypass;
    input clk;
    input [1:0] DMCtrl;
    output [31:0] RD;

    wire active_rw = (DMCtrl == 2'b10) || (DMCtrl == 2'b01);
    wire [10:0] sram_addr = {1'b0, Addr_bypass};
    wire [63:0] sram_din = {32'b0, WD_bypass};
    wire [63:0] sram_dout;
    wire        sram_ceb = ~active_rw;
    wire        sram_wen = ~(DMCtrl == 2'b10);
    wire [63:0] sram_bweb = (DMCtrl == 2'b10) ? {32'hFFFFFFFF, 32'h00000000} : 64'hFFFFFFFF_FFFFFFFF;

    // 例化 SRAM 宏 (直接使用 clk)
    TS1N65LPLL2048X64M8 memory (
        .A   (sram_addr),
        .D   (sram_din),
        .Q   (sram_dout),
        .CLK (clk),                      
        .CEB (sram_ceb),
        .WEB (sram_wen),
        .BWEB(sram_bweb),
        .TSEL(2'b01)
    );

    assign RD = sram_dout[31:0];

endmodule