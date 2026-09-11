class gpu_coverage_closure_seq extends gpu_base_vseq;
    `uvm_object_utils(gpu_coverage_closure_seq)

    int prog_sel = 1;

    function new(string name = "gpu_coverage_closure_seq");
        super.new(name);
    endfunction

    virtual function void build_program();
        case (prog_sel)
            1: branch_prog_a();
            2: branch_prog_b();
            3: branch_prog_c();
            4: alu_prog();
            5: prot_prog();
        endcase
    endfunction

    function void branch_prog_a();
        prog = '{
            instr_const(REG_R1, 8'h01),
            instr_const(REG_R2, 8'h00),
            instr_cmp(REG_R1, REG_R2),
            instr_brnzp(3'b001, 8'h06),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b010, 8'h09),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b100, 8'h0C),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b011, 8'h0F),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b101, 8'h12),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b110, 8'h15),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b111, 8'h18),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_ret()
        };
    endfunction

    function void branch_prog_b();
        prog = '{
            instr_const(REG_R1, 8'h00),
            instr_const(REG_R2, 8'h01),
            instr_cmp(REG_R1, REG_R2),
            instr_brnzp(3'b001, 8'h06),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b010, 8'h09),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b100, 8'h0C),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b011, 8'h0F),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b101, 8'h12),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b110, 8'h15),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_brnzp(3'b111, 8'h18),  instr_const(REG_R14, 8'hEE), instr_const(REG_R13, 8'hDD),
            instr_ret()
        };
    endfunction

    function void branch_prog_c();
        prog = '{
            instr_brnzp(3'b111, 8'h04),
            instr_brnzp(3'b101, 8'h04),
            instr_nop(),
            instr_nop(),
            instr_const(REG_R1, 8'h05),
            instr_const(REG_R2, 8'h05),
            instr_cmp(REG_R1, REG_R2),
            instr_brnzp(3'b010, 8'h0A),  instr_const(REG_R14, 8'hEE),
            instr_nop(),
            instr_ret()
        };
    endfunction

    function void alu_prog();
        int alu_pairs[10][2] = '{
            '{8'h00, 8'h00}, '{8'h01, 8'h01}, '{8'h7F, 8'h80},
            '{8'h80, 8'hFF}, '{8'hFF, 8'hFF}, '{8'hC8, 8'hC8},
            '{8'h00, 8'h01}, '{8'h14, 8'h14}, '{8'h05, 8'h00},
            '{8'hFF, 8'h07}
        };
        prog.delete();
        foreach (alu_pairs[i]) begin
            prog.push_back(instr_const(REG_R1, alu_pairs[i][0][7:0]));
            prog.push_back(instr_const(REG_R2, alu_pairs[i][1][7:0]));
            prog.push_back(instr_add(REG_R3, REG_R1, REG_R2));
            prog.push_back(instr_sub(REG_R4, REG_R1, REG_R2));
            prog.push_back(instr_mul(REG_R5, REG_R1, REG_R2));
            prog.push_back(instr_div(REG_R6, REG_R1, REG_R2));
        end
        prog.push_back(instr_ret());
    endfunction

    function void prot_prog();
        prog = '{
            instr_const(REG_R1, 8'h05),
            instr_const(REG_R2, 8'h05),
            instr_cmp(REG_R1, REG_R2),
            instr_const(REG_R13, 8'h55),
            instr_const(REG_R14, 8'h66),
            instr_const(REG_R15, 8'h77),
            instr_raw(16'hA000),
            instr_raw(16'hB123),
            instr_raw(16'hC456),
            instr_raw(16'hD789),
            instr_raw(16'hEABC),
            instr_nop(),
            instr_ret()
        };
    endfunction
endclass


class gpu_coverage_closure_test extends gpu_base_test;
    `uvm_component_utils(gpu_coverage_closure_test)

    function new(string name = "gpu_coverage_closure_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_coverage_closure_seq seq;
        string labels[5] = '{"branch A (positive)", "branch B (negative)",
                            "branch C (zero+reset-nzp)", "ALU boundary",
                            "protect+unused"};

        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== Coverage closure: 5 kernels (branch A/B/C, ALU, protect+unused) ===", UVM_LOW)

        for (int k = 1; k <= 5; k++) begin
            `uvm_info("TEST", $sformatf("--- Kernel %0d: %s ---", k, labels[k-1]), UVM_LOW)
            seq = gpu_coverage_closure_seq::type_id::create("seq");
            seq.num_threads = 1;
            seq.prog_sel = k;
            seq.start(env.v_seqr, null, -1, 0);
            seq.wait_kernel_done(labels[k-1]);

            seq.clear_start();

            begin
                rst_item r_item = rst_item::type_id::create("r_item");
                r_item.duration_ns = 20;
                env.rst_ag.sequencer.execute_item(r_item);
            end
            #50ns;
        end

        `uvm_info("TEST", "Coverage closure test finished successfully!", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
