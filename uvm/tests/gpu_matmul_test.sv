class gpu_matmul_test extends gpu_base_test;
    `uvm_component_utils(gpu_matmul_test)

    function new(string name = "gpu_matmul_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_kernel_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = 4;
        seq.prog = '{
            instr_mul(REG_R0, REG_BLOCK_IDX, REG_BLOCK_DIM),
            instr_add(REG_R0, REG_R0, REG_THREAD_ID),
            instr_const(REG_R1, 8'h01),
            instr_const(REG_R2, 8'h02),
            instr_const(REG_R3, 8'h00),
            instr_const(REG_R4, 8'h04),
            instr_const(REG_R5, 8'h08),
            instr_div(REG_R6, REG_R0, REG_R2),
            instr_mul(REG_R7, REG_R6, REG_R2),
            instr_sub(REG_R7, REG_R0, REG_R7),
            instr_const(REG_R8, 8'h00),
            instr_const(REG_R9, 8'h00),
            instr_mul(REG_R10, REG_R6, REG_R2),
            instr_add(REG_R10, REG_R10, REG_R9),
            instr_add(REG_R10, REG_R10, REG_R3),
            instr_ldr(REG_R10, REG_R10),
            instr_mul(REG_R11, REG_R9, REG_R2),
            instr_add(REG_R11, REG_R11, REG_R7),
            instr_add(REG_R11, REG_R11, REG_R4),
            instr_ldr(REG_R11, REG_R11),
            instr_mul(REG_R12, REG_R10, REG_R11),
            instr_add(REG_R8, REG_R12, REG_R8),
            instr_add(REG_R9, REG_R9, REG_R1),
            instr_cmp(REG_R2, REG_R0),
            instr_cmp(REG_R0, REG_R12),
            instr_add(REG_R9, REG_R5, REG_R0),
            instr_str(REG_R9, REG_R8),
            instr_ret()
        };
        seq.data_bytes = '{8'h01, 8'h02, 8'h03, 8'h04,
                           8'h01, 8'h02, 8'h03, 8'h04};
        seq.start(env.v_seqr, null, -1, 0);

        `uvm_info("TEST", "MatMul launched (EXPECTED TO HANG: ALU BRn bug)", UVM_LOW)
        seq.wait_kernel_done("MatMul (expected hang)", 1);

        #(env.cfg.post_done_drain_ns * 1ns);
        phase.drop_objection(this);
    endtask
endclass
