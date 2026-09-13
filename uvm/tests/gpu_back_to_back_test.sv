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
        launch_and_wait_checked(seq, "Kernel 1 (MatAdd 8t)");

        `uvm_info("TEST", "=== KERNEL 2: MatAdd 4 threads (no reset!) ===", UVM_LOW)
        if (env.cfg.en_scoreboard) env.scoreboard.reset();
        seq = new_matadd(4);
        launch_and_wait_checked(seq, "Kernel 2 (MatAdd 4t, no reset)");

        `uvm_info("TEST", "=== KERNEL 3: MatAdd 8 threads (no reset!) ===", UVM_LOW)
        if (env.cfg.en_scoreboard) env.scoreboard.reset();
        seq = new_matadd(8);
        launch_and_wait_checked(seq, "Kernel 3 (MatAdd 8t, no reset)");

        `uvm_info("TEST", "Back-to-back test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
