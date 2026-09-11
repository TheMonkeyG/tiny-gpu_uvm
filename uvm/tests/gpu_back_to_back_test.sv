class gpu_back_to_back_test extends gpu_base_test;
    `uvm_component_utils(gpu_back_to_back_test)

    function new(string name = "gpu_back_to_back_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_kernel_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== KERNEL 1: MatAdd 8 threads ===", UVM_LOW)
        seq = new_matadd(8);
        seq.start(env.v_seqr, null, -1, 0);
        wait_done_or_timeout("Kernel 1 (MatAdd 8t)");
        seq.clear_start();

        `uvm_info("TEST", "=== KERNEL 2: MatAdd 4 threads (no reset!) ===", UVM_LOW)
        if (env.cfg.en_scoreboard) env.scoreboard.reset();
        seq = new_matadd(4);
        seq.start(env.v_seqr, null, -1, 0);
        wait_done_or_timeout("Kernel 2 (MatAdd 4t, no reset)");
        seq.clear_start();

        `uvm_info("TEST", "=== KERNEL 3: MatAdd 8 threads (no reset!) ===", UVM_LOW)
        if (env.cfg.en_scoreboard) env.scoreboard.reset();
        seq = new_matadd(8);
        seq.start(env.v_seqr, null, -1, 0);
        wait_done_or_timeout("Kernel 3 (MatAdd 8t, no reset)");
        seq.clear_start();

        `uvm_info("TEST", "Back-to-back test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

    function gpu_kernel_seq new_matadd(int unsigned threads);
        gpu_kernel_seq seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = threads;
        seq.data_base = 0;
        gpu_program_lib::matadd(seq.prog, seq.data_bytes);
        return seq;
    endfunction

    task wait_done_or_timeout(string label);
        fork
            begin
                real t_start, t_end;
                t_start = $realtime;
                env.done_ag.monitor.wait_for_done();
                t_end = $realtime;
                if ((t_end - t_start) < 50)
                    `uvm_error("TEST", $sformatf("%s: done too fast (%.0fns)! Sticky done?", label, t_end - t_start))
                else
                    `uvm_info("TEST", $sformatf("%s PASS: done after %.0fns", label, t_end - t_start), UVM_LOW)
            end
            begin
                #(env.cfg.watchdog_timeout_ns * 1ns);
                `uvm_error("TEST_TIMEOUT", $sformatf("%s: GPU hung!", label))
            end
        join_any
        disable fork;
        #(env.cfg.post_done_drain_ns * 1ns);
    endtask
endclass
