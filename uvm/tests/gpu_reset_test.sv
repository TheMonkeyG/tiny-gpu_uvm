class gpu_reset_test extends gpu_base_test;
    `uvm_component_utils(gpu_reset_test)

    function new(string name = "gpu_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_kernel_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== S1: 5 consecutive resets (no kernel) ===", UVM_LOW)
        repeat (5) begin inject_reset(10); #20ns; end

        `uvm_info("TEST", "=== S2: start -> reset -> reset -> launch ===", UVM_LOW)
        launch_trivial(4);
        #50ns; inject_reset(15);
        #30ns; inject_reset(15);
        #30ns;
        launch_matadd_and_wait(4, "S2 clean launch");
        post_kernel_cleanup();

        `uvm_info("TEST", "=== S3: 3 fast resets -> launch ===", UVM_LOW)
        repeat (3) begin inject_reset(10); #10ns; end
        launch_matadd_and_wait(8, "S3 after rapid resets");
        post_kernel_cleanup();

        `uvm_info("TEST", "=== S4: reset immediately after done ===", UVM_LOW)
        begin
            gpu_kernel_seq seq4a = new_matadd(4);
            seq4a.start(env.v_seqr, null, -1, 0);
        end
        env.done_ag.monitor.wait_for_done();
        #5ns;
        inject_reset(20);
        #20ns;
        launch_matadd_and_wait(4, "S4 after post-done reset");
        post_kernel_cleanup();

        `uvm_info("TEST", "=== S5: reset mid-execution (~200ns) -> recovery ===", UVM_LOW)
        begin
            gpu_kernel_seq seq5a = new_matadd(8);
            seq5a.start(env.v_seqr, null, -1, 0);
        end
        #200ns;
        inject_reset(30);
        #50ns;
        launch_matadd_and_wait(8, "S5 recovery after mid-exec reset");
        post_kernel_cleanup();

        `uvm_info("TEST", "=== S6: reset 1 cycle after start (early abort) ===", UVM_LOW)
        begin
            gpu_kernel_seq seq6a = gpu_kernel_seq::type_id::create("seq6a");
            seq6a.num_threads = 8;
            gpu_program_lib::scatter(seq6a.prog, 8'h20);
            seq6a.start(env.v_seqr, null, -1, 0);
        end
        #10ns;
        inject_reset(20);
        #50ns;
        launch_matadd_and_wait(4, "S6 recovery after early-abort reset");
        post_kernel_cleanup();

        `uvm_info("TEST", "=== S7: reset during STR (LSU WAITING) -> recovery ===", UVM_LOW)
        begin
            gpu_kernel_seq seq7a = gpu_kernel_seq::type_id::create("seq7a");
            seq7a.num_threads = 8;
            gpu_program_lib::arbiter(seq7a.prog);
            seq7a.start(env.v_seqr, null, -1, 0);
        end
        #400ns;
        inject_reset(30);
        #100ns;
        launch_matadd_and_wait(8, "S7 recovery after reset-during-STR");

        `uvm_info("TEST", "Reset test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

    task launch_trivial(int unsigned threads);
        gpu_kernel_seq seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = threads;
        gpu_program_lib::trivial(seq.prog);
        seq.start(env.v_seqr, null, -1, 0);
    endtask

    task launch_matadd_and_wait(int unsigned threads, string label);
        gpu_kernel_seq seq = new_matadd(threads);
        launch_and_wait(seq, label);
    endtask
endclass
