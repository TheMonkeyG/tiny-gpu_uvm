class gpu_features_test extends gpu_base_test;
    `uvm_component_utils(gpu_features_test)

    function new(string name = "gpu_features_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_kernel_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== F1: arbiter (32 writes, high bus contention) ===", UVM_LOW)
        seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = 8;
        gpu_program_lib::arbiter(seq.prog);
        launch_and_wait(seq, "arbiter");
        post_kernel_cleanup();

        `uvm_info("TEST", "=== F2: scatter, 2 blocks (dual-block done) ===", UVM_LOW)
        seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = 8;
        gpu_program_lib::scatter(seq.prog, 8'h20);
        launch_and_wait(seq, "dual-block scatter");

        `uvm_info("TEST", "Features test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
