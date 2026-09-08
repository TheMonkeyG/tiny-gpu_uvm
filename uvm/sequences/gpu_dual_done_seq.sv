class gpu_dual_done_seq extends gpu_base_vseq;
    `uvm_object_utils(gpu_dual_done_seq)

    function new(string name = "gpu_dual_done_seq");
        super.new(name);
    endfunction

    virtual task body();
        logic [15:0] prog[$] = '{
            16'h51DE,
            16'h321F,
            16'h9320,
            16'h3323,
            16'h803F,
            16'hF000
        };

        logic [7:0] zeros[$];
        for (int i = 0; i < 48; i++) zeros.push_back(8'h00);

        load_program(prog);
        load_data(0, zeros);
        launch_kernel(8);
        `uvm_info("DUAL_DONE_SEQ", "8 threads (2 blocks) — simultaneous completion test", UVM_LOW)
    endtask
endclass
