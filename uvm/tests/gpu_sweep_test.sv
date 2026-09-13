class gpu_sweep_seq extends gpu_kernel_seq;
    `uvm_object_utils(gpu_sweep_seq)

    int prog_sel = 1;

    function new(string name = "gpu_sweep_seq");
        super.new(name);
    endfunction

    virtual function void build_program();
        case (prog_sel)
            1: trivial_prog();
            2: matadd_prog();
            3: scatter_prog();
            4: alu_prog();
            5: branch_prog_a();
            6: branch_prog_b();
            7: branch_prog_c();
            8: prot_prog();
        endcase
    endfunction

    function void trivial_prog();
        gpu_program_lib::trivial(prog);
    endfunction

    function void matadd_prog();
        gpu_program_lib::matadd(prog, data_bytes);
        data_base = 0;
    endfunction

    function void scatter_prog();
        gpu_program_lib::scatter(prog, 8'h10);
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


class gpu_sweep_test extends gpu_base_test;
    `uvm_component_utils(gpu_sweep_test)

    int progs[] = '{1, 2, 3, 4, 5, 6, 7, 8};
    int threads_list[] = '{1, 2, 3, 4, 5, 6, 7, 8, 9};

    function new(string name = "gpu_sweep_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_sweep_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        foreach (progs[pi]) begin
            foreach (threads_list[ti]) begin
                int t = threads_list[ti];
                seq = gpu_sweep_seq::type_id::create("seq");
                seq.prog_sel = progs[pi];
                seq.num_threads = t;
                `uvm_info("TEST", $sformatf("=== sweep: prog=%0d threads=%0d ===", progs[pi], t), UVM_LOW)
                launch_and_wait(seq, $sformatf("prog=%0d threads=%0d", progs[pi], t));
                post_kernel_cleanup();
            end
        end

        `uvm_info("TEST", "Sweep test finished successfully!", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
