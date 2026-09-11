class gpu_corner_test extends gpu_base_test;
    `uvm_component_utils(gpu_corner_test)

    function new(string name = "gpu_corner_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== Case 1: Trivial (CONST+RET), 1 thread ===", UVM_LOW)
        run_trivial(1);
        do_reset();

        `uvm_info("TEST", "=== Case 2: MatAdd, 1 thread ===", UVM_LOW)
        run_matadd(1);
        do_reset();

        `uvm_info("TEST", "=== Case 3: MatAdd, 4 threads (full block) ===", UVM_LOW)
        run_matadd(4);
        do_reset();

        `uvm_info("TEST", "=== Case 4: MatAdd, 5 threads (partial block) ===", UVM_LOW)
        run_matadd(5);
        do_reset();

        `uvm_info("TEST", "Corner case tests finished", UVM_LOW)
        phase.drop_objection(this);
    endtask

    virtual task run_trivial(int unsigned threads);
        gpu_kernel_seq seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = threads;
        gpu_program_lib::trivial(seq.prog);
        seq.start(env.v_seqr, null, -1, 0);
        seq.wait_kernel_done("Trivial kernel");
        #50ns;
    endtask

    virtual task run_matadd(int unsigned threads);
        gpu_kernel_seq seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = threads;
        seq.data_base = 0;
        gpu_program_lib::matadd(seq.prog, seq.data_bytes);
        seq.start(env.v_seqr, null, -1, 0);
        seq.wait_kernel_done($sformatf("MatAdd %0d threads", threads));
        #(env.cfg.post_done_drain_ns * 1ns);
    endtask

    virtual task do_reset();
        host_ctrl_item h_clr = host_ctrl_item::type_id::create("h_clr");
        h_clr.is_start_clear = 1;
        env.host_agent.sequencer.execute_item(h_clr);
        if (env.cfg.en_coverage) env.coverage_col.reset();
        begin
            rst_item r = rst_item::type_id::create("r");
            r.duration_ns = 20;
            env.rst_ag.sequencer.execute_item(r);
        end
        #50ns;
    endtask
endclass
