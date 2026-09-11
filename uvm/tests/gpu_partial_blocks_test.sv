class gpu_partial_blocks_test extends gpu_base_test;
    `uvm_component_utils(gpu_partial_blocks_test)

    function new(string name = "gpu_partial_blocks_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        start_clk_and_reset();

        for (int t = 1; t <= 8; t++) begin
            `uvm_info("TEST", $sformatf("=== Partial block test: %0d thread(s) ===", t), UVM_LOW)
            run_with_n_threads(t);

            seq_clear_and_reset();
        end

        `uvm_info("TEST", "All partial-block tests complete (1..8 threads)", UVM_LOW)
        phase.drop_objection(this);
    endtask

    task run_with_n_threads(int n);
        gpu_kernel_seq seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = n;
        gpu_program_lib::scatter(seq.prog, 8'h10);
        seq.start(env.v_seqr, null, -1, 0);
        seq.wait_kernel_done($sformatf("%0d thread(s)", n));
        `uvm_info("TEST", $sformatf("PASS: %0d thread(s)", n), UVM_LOW)
        #(env.cfg.post_done_drain_ns * 1ns);
    endtask

    task seq_clear_and_reset();
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
