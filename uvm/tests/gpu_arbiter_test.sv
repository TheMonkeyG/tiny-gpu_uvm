class gpu_arbiter_test extends gpu_base_test;
    `uvm_component_utils(gpu_arbiter_test)

    function new(string name = "gpu_arbiter_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_kernel_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = 8;
        gpu_program_lib::arbiter(seq.prog);
        seq.start(env.v_seqr, null, -1, 0);

        `uvm_info("TEST", "Waiting for GPU done (32 writes, high bus contention)...", UVM_LOW)
        seq.wait_kernel_done("arbiter (no writes lost)");
        `uvm_info("TEST", "PASS: arbiter test", UVM_LOW)

        #(env.cfg.post_done_drain_ns * 1ns);
        seq.clear_start();
        phase.drop_objection(this);
    endtask
endclass
