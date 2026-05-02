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

    function automatic bit is_pass;
        input [8*24-1:0] name;
        begin
            case (name)
                "t01_ralu": is_pass = (U_RISCV.U_RF.register[15] == 32'h00000000);
                "t02_itype": is_pass = (U_RISCV.U_RF.register[4] == 32'hFFFFFF01);
                "t03_mem": is_pass = (U_RISCV.U_RF.register[5] == 32'h00000456);
                "t04_beq_taken": is_pass = (U_RISCV.U_RF.register[4] == 32'h00000001);
                "t05_beq_not_taken": is_pass = (U_RISCV.U_RF.register[5] == 32'h00000001);
                "t06_bne": is_pass = (U_RISCV.U_RF.register[10] == 32'h00000001);
                "t07_jal_link": is_pass = (U_RISCV.U_RF.register[12] == 32'h00000001);
                "t08_jalr": is_pass = (U_RISCV.U_RF.register[30] == 32'h00000000);
                "t09_x0": is_pass = (U_RISCV.U_RF.register[1] == 32'h00000066);
                "t10_loop_bne": is_pass = (U_RISCV.U_RF.register[1] == 32'h00000003);
                "t11_jal_back": is_pass = (U_RISCV.U_RF.register[3] == 32'h00000003);
                "t12_sw_neg": is_pass = (U_RISCV.U_RF.register[3] == 32'h00000000);
                "t13_shift_boundary": is_pass = (U_RISCV.U_RF.register[13] == 32'h00000000);
                "t14_add_negative": is_pass = (U_RISCV.U_RF.register[13] == 32'h00000000);
                "t15_bne_false": is_pass = (U_RISCV.U_RF.register[8] == 32'h00000088);
                "t16_lw_negative_extend": is_pass = (U_RISCV.U_RF.register[9] == 32'h00000028);
                "t17_addi_bounds": is_pass = (U_RISCV.U_RF.register[20] == 32'hFFFFFFFF);
                "t18_ori_and": is_pass = (U_RISCV.U_RF.register[20] == 32'h000007FF);
                "t19_xor_sign": is_pass = (U_RISCV.U_RF.register[20] == 32'hFFFFFFFE);
                "t20_sub_self": is_pass = (U_RISCV.U_RF.register[20] == 32'h00000000);
                "t21_srl_rs0": is_pass = (U_RISCV.U_RF.register[20] == 32'h0000007B);
                "t22_sll31": is_pass = (U_RISCV.U_RF.register[20] == 32'h80000000);
                "t23_beq_always": is_pass = (U_RISCV.U_RF.register[20] == 32'h00000042);
                "t24_jal_jalr_ret": is_pass = (U_RISCV.U_RF.register[20] == 32'h00000033) && (U_RISCV.U_RF.register[21] == 32'h000000AA);
                "t25_sw_overwrite": is_pass = (U_RISCV.U_RF.register[20] == 32'h00000222);
                "t26_alu_chain": is_pass = (U_RISCV.U_RF.register[20] == 32'h00000010);
                "t27_sra_neg1": is_pass = (U_RISCV.U_RF.register[20] == 32'hFFFFFFFF);
                "t28_bne_taken": is_pass = (U_RISCV.U_RF.register[20] == 32'h00000056);
                "t29_or_combine": is_pass = (U_RISCV.U_RF.register[20] == 32'h000000FF);
                "t30_sw_lw_min_offset": is_pass = (U_RISCV.U_RF.register[20] == 32'h000003EF);
                "t31_jalr_imm": is_pass = (U_RISCV.U_RF.register[20] == 32'h000000CC);
                "t32_add_maxint_wrap": is_pass = (U_RISCV.U_RF.register[20] == 32'h80000000);
                "t33_sra_pos_msb": is_pass = (U_RISCV.U_RF.register[20] == 32'h00000000);
                "t34_lw_x0_rs": is_pass = (U_RISCV.U_RF.register[21] == 32'h00000005);
                "t35_mem_chain_offsets": is_pass = (U_RISCV.U_RF.register[20] == 32'h00000101);
                "t36_bne_loop10": is_pass = (U_RISCV.U_RF.register[20] == 32'h0000000A);
                "t37_beq_fallthrough2": is_pass = (U_RISCV.U_RF.register[20] == 32'h0000003D);
                "t38_sub_from_zero": is_pass = (U_RISCV.U_RF.register[20] == 32'h80000000);
                default: is_pass = 1'b0;
            endcase
        end
    endfunction

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
        timeout_cycles = 500000;
        if (!$value$plusargs("TIMEOUT=%d", timeout_cycles)) begin
            timeout_cycles = 500000;
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

            if (stable_pc_cycles >= 2) begin
                if (is_pass(test_name)) begin
                    $display("\n==================== TEST PASS ====================");
                    $display("  Test      : %0s", test_name);
                    $display("  Final PC  : 0x%08X", U_RISCV.U_PC.PC);
                    $display("  Cycles    : %0d", cycle_count);
                    $display("====================================================\n");
                    $finish;
                end else begin
                    $display("\n==================== TEST FAIL ====================");
                    $display("  Test      : %0s", test_name);
                    $display("  Final PC  : 0x%08X", U_RISCV.U_PC.PC);
                    $display("  Cycles    : %0d", cycle_count);
                    $display("  Last IR   : 0x%08X", U_RISCV.out_ins);
                    $display("====================================================\n");
                    $fatal(1, "Register result mismatch");
                end
            end

            if (cycle_count >= timeout_cycles) begin
                $display("\n==================== TIMEOUT EXIT ====================");
                $display("  Test      : %0s", test_name);
                $display("  Reason    : Reached timeout limit of %0d cycles", cycle_count);
                $display("  Last PC   : 0x%08X", U_RISCV.U_PC.PC);
                $display("  Last IR   : 0x%08X", U_RISCV.out_ins);
                $display("====================================================\n");
                $fatal(1, "Simulation timeout");
            end
        end
    end

    initial begin
        $fsdbDumpvars(0, "riscv_sim");
        $fsdbDumpMDA(0, "riscv_sim");
    end

endmodule
