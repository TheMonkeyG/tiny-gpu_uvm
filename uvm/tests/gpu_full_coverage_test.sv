class gpu_full_coverage_seq extends gpu_base_vseq;
    `uvm_object_utils(gpu_full_coverage_seq)

    function new(string name = "gpu_full_coverage_seq");
        super.new(name);
    endfunction

    virtual function void build_program();
        prog = '{
            instr_const(REG_R1, 8'h10),
            instr_const(REG_R2, 8'h50),
            instr_add(REG_R3, REG_R1, REG_R2),
            instr_sub(REG_R4, REG_R1, REG_R2),
            instr_mul(REG_R5, REG_R1, REG_R2),
            instr_div(REG_R6, REG_R1, REG_R2),
            instr_cmp(REG_R1, REG_R2),
            instr_brnzp(3'b000, 8'h00),
            instr_nop(),
            instr_const(REG_R1, 8'h00),
            instr_const(REG_R2, 8'h05),
            instr_str(REG_R1, REG_R2),
            instr_ldr(REG_R1, REG_R1),
            instr_ret()
        };
    endfunction
endclass

class gpu_full_coverage_test extends gpu_base_test;
    `uvm_component_utils(gpu_full_coverage_test)

    function new(string name = "gpu_full_coverage_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_full_coverage_seq seq;
        int tcounts[] = '{1, 2, 4, 5, 8, 9};

        phase.raise_objection(this);
        start_clk_and_reset();

        foreach (tcounts[i]) begin
            `uvm_info("TEST", $sformatf("=== Coverage Iteration: %0d threads ===", tcounts[i]), UVM_LOW)
            seq = gpu_full_coverage_seq::type_id::create("seq");
            seq.num_threads = tcounts[i];

            seq.start(env.v_seqr, null, -1, 0);
            seq.wait_kernel_done($sformatf("coverage %0d threads", tcounts[i]));

            seq.clear_start();

            begin
                rst_item r_item = rst_item::type_id::create("r_item");
                r_item.duration_ns = 20;
                env.rst_ag.sequencer.execute_item(r_item);
            end
            #50ns;
        end

        `uvm_info("TEST", "Full coverage test finished successfully!", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
