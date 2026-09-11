class gpu_dual_done_test extends gpu_base_test;
    `uvm_component_utils(gpu_dual_done_test)

    function new(string name = "gpu_dual_done_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_kernel_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = 8;
        gpu_program_lib::scatter(seq.prog, 8'h20);
        seq.start(env.v_seqr, null, -1, 0);
        seq.wait_kernel_done("dual-block done");

        `uvm_info("TEST", "PASS: dual-block done", UVM_LOW)
        #(env.cfg.post_done_drain_ns * 1ns);
        seq.clear_start();
        phase.drop_objection(this);
    endtask
endclass
