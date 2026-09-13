class gpu_stress_test extends gpu_base_test;
    `uvm_component_utils(gpu_stress_test)

    function new(string name = "gpu_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_kernel_seq seq;
        phase.raise_objection(this);
        start_clk_and_reset();

        for (int iteration = 0; iteration < 5; iteration++) begin
            seq = gpu_kernel_seq::type_id::create("seq");
            if (!seq.randomize()) `uvm_fatal("TEST", "Randomization failed")
            seq.num_threads = 8;
            gpu_program_lib::matadd(seq.prog, seq.data_bytes, .random_data(1));

            `uvm_info("TEST", $sformatf("=== ITERATION %0d: %0d threads ===", iteration, seq.num_threads), UVM_LOW)
            launch_and_wait(seq, $sformatf("stress iteration %0d", iteration));
            post_kernel_cleanup();
        end

        `uvm_info("TEST", "Stress test finished successfully!", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
