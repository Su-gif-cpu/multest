`timescale 1ns / 1ps

module riscv_sim();
    parameter PC_BASE = 32'h00002000;

    reg clk;
    reg rst;
    reg [8*24-1:0] test_name;
    reg [8*64-1:0] hex_path;
    integer cycle_count;
    integer timeout_cycles;
    integer stable_pc_cycles;
    reg [31:0] last_pc;
    integer i;

    // Pass/fail checks removed - waveform inspection only

    riscv U_RISCV(
        .clk(clk),
        .rst(rst)
    );

    initial begin
        test_name = "t01_ralu";
        if (!$value$plusargs("TEST=%s", test_name)) begin
            test_name = "t01_ralu";
        end

        hex_path = {"../hex/", test_name, ".hex"};
        $display("\n====================================================");
        $display("  TESTBENCH START: %0s", test_name);
        $display("  Instruction ROM: %0s", hex_path);
        $display("====================================================\n");

        for (i = 1; i < 32; i = i + 1) begin
            U_RISCV.U_RF.register[i] = 32'h0;
        end
        for (i = 0; i < 1024; i = i + 1) begin
            U_RISCV.U_DM.memory[i] = 32'h0;
        end

        $readmemh(hex_path, U_RISCV.U_IM.memory);

        clk = 1'b1;
        rst = 1'b1;
        #20;
        rst = 1'b0;

        cycle_count = 0;
        timeout_cycles = 50000;
        if (!$value$plusargs("TIMEOUT=%d", timeout_cycles)) begin
            timeout_cycles = 50000;
        end
        stable_pc_cycles = 0;
        last_pc = 32'hDEAD_BEEF;
    end

    always #50 clk = ~clk;

    always @(posedge clk) begin
        if (!rst) begin
            cycle_count = cycle_count + 1;

            if (U_RISCV.U_PC.PC == last_pc) begin
                stable_pc_cycles = stable_pc_cycles + 1;
            end else begin
                stable_pc_cycles = 0;
            end
            last_pc = U_RISCV.U_PC.PC;

            if (cycle_count >= timeout_cycles) begin
                $display("\n==================== SIMULATION COMPLETE ====================");
                $display("  Test      : %0s", test_name);
                $display("  Cycles    : %0d", cycle_count);
                $display("  Last PC   : 0x%08X", U_RISCV.U_PC.PC);
                $display("  Last IR   : 0x%08X", U_RISCV.out_ins);
                $display("====================================================\n");
                $finish;
            end
        end
    end

    initial begin
        $fsdbDumpvars(0, "riscv_sim");
        $fsdbDumpMDA(0, "riscv_sim");
    end

endmodule
