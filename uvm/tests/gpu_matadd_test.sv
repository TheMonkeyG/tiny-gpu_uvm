class gpu_matadd_test extends gpu_base_test;
    `uvm_component_utils(gpu_matadd_test)

    function new(string name = "gpu_matadd_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_kernel_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "Starting MatAdd (8 threads)", UVM_LOW)
        seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = 8;
        seq.data_base = 0;
        gpu_program_lib::matadd(seq.prog, seq.data_bytes);
        seq.start(env.v_seqr, null, -1, 0);
        seq.wait_kernel_done("MatAdd");

        #(env.cfg.post_done_drain_ns * 1ns);
        seq.clear_start();
        phase.drop_objection(this);
    endtask
endclass
