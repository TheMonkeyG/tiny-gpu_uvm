class gpu_reset_mid_exec_test extends gpu_base_test;
    `uvm_component_utils(gpu_reset_mid_exec_test)

    function new(string name = "gpu_reset_mid_exec_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_kernel_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== SCENARIO 1: Reset mid-execution (after ~200ns) ===", UVM_LOW)
        launch_matadd(8);
        #200ns;
        `uvm_info("TEST", "Injecting RESET mid-execution!", UVM_LOW)
        inject_reset(30);
        #50ns;
        if (env.cfg.en_coverage) env.coverage_col.reset();

        `uvm_info("TEST", "Post-reset: launching clean kernel to verify GPU recovered", UVM_LOW)
        launch_matadd(8);
        fork
            begin
                env.done_ag.monitor.wait_for_done();
                `uvm_info("TEST", "SCENARIO 1 PASS: GPU recovered after mid-exec reset", UVM_LOW)
            end
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST_TIMEOUT", "GPU did not recover after mid-execution reset!")
            end
        join_any
        disable fork;
        #(env.cfg.post_done_drain_ns * 1ns);

        do_host_clear();
        if (env.cfg.en_coverage) env.coverage_col.reset();
        inject_reset(20);
        #50ns;

        `uvm_info("TEST", "=== SCENARIO 2: Reset 1 cycle after start (early abort) ===", UVM_LOW)
        launch_dual_done();
        #10ns;
        `uvm_info("TEST", "Injecting IMMEDIATE RESET (1 cycle after start)!", UVM_LOW)
        inject_reset(20);
        #50ns;
        if (env.cfg.en_coverage) env.coverage_col.reset();

        `uvm_info("TEST", "Post early-reset: launching clean 4-thread kernel", UVM_LOW)
        launch_matadd(4);
        fork
            begin
                env.done_ag.monitor.wait_for_done();
                `uvm_info("TEST", "SCENARIO 2 PASS: GPU recovered after immediate reset", UVM_LOW)
            end
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST_TIMEOUT", "GPU stuck after early-abort reset!")
            end
        join_any
        disable fork;
        #(env.cfg.post_done_drain_ns * 1ns);

        do_host_clear();
        `uvm_info("TEST", "Reset mid-exec test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

    task launch_matadd(int unsigned threads);
        gpu_kernel_seq seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = threads;
        seq.data_base = 0;
        gpu_program_lib::matadd(seq.prog, seq.data_bytes);
        seq.start(env.v_seqr, null, -1, 0);
    endtask

    task launch_dual_done();
        gpu_kernel_seq seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = 8;
        gpu_program_lib::scatter(seq.prog, 8'h20);
        seq.start(env.v_seqr, null, -1, 0);
    endtask

    task inject_reset(int duration_ns);
        rst_item r = rst_item::type_id::create("r");
        r.duration_ns = duration_ns;
        env.rst_ag.sequencer.execute_item(r);
    endtask

    task do_host_clear();
        host_ctrl_item h_clr = host_ctrl_item::type_id::create("h_clr");
        h_clr.is_start_clear = 1;
        env.host_agent.sequencer.execute_item(h_clr);
    endtask
endclass
