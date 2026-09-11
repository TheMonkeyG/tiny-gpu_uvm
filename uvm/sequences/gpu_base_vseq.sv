class gpu_base_vseq extends uvm_sequence;
    `uvm_object_utils(gpu_base_vseq)
    `uvm_declare_p_sequencer(gpu_virtual_sequencer)

    rand int unsigned num_threads;
    constraint c_num_threads { num_threads inside {[1:64]}; }

    rand int unsigned data_base;
    constraint c_data_base { data_base inside {[0:200]}; }

    gpu_instr_t prog[$];

    logic [7:0] data_bytes[$];

    function new(string name = "gpu_base_vseq");
        super.new(name);
    endfunction

    virtual function void build_program();
    endfunction

    virtual task body();
        build_program();
        if (data_bytes.size() > 0) load_data(data_base, data_bytes);
        load_program();
        launch_kernel(num_threads);
    endtask


    virtual task load_program();
        foreach (prog[i]) begin
            memory_item m = memory_item::type_id::create("m");
            m.op = WRITE; m.addr = i; m.data = encode(prog[i]);
            p_sequencer.prog_seqr.execute_item(m);
        end
        `uvm_info("VSEQ", $sformatf("Loaded %0d instructions", prog.size()), UVM_MEDIUM)
    endtask

    virtual task load_data(int base_addr, logic [7:0] data[$]);
        foreach (data[i]) begin
            memory_item m = memory_item::type_id::create("m");
            m.op = WRITE; m.addr = base_addr + i; m.data = data[i];
            p_sequencer.data_seqr.execute_item(m);
        end
        `uvm_info("VSEQ", $sformatf("Loaded %0d bytes at 0x%02h", data.size(), base_addr), UVM_MEDIUM)
    endtask

    virtual task launch_kernel(int unsigned thread_count);
        host_ctrl_item h;
        h = host_ctrl_item::type_id::create("h");
        h.is_write = 1; h.data = thread_count;
        p_sequencer.host_seqr.execute_item(h);

        h = host_ctrl_item::type_id::create("h2");
        h.is_write = 0;
        p_sequencer.host_seqr.execute_item(h);
        `uvm_info("VSEQ", $sformatf("Launched %0d threads", thread_count), UVM_LOW)
    endtask

    virtual task wait_kernel_done(string label = "kernel", bit expect_timeout = 0);
        bit timed_out = 0;
        fork
            begin
                p_sequencer.done_mon.wait_for_done();
            end
            begin
                #(p_sequencer.watchdog_timeout_ns * 1ns);
                timed_out = 1;
            end
        join_any
        disable fork;
        if (timed_out) begin
            if (expect_timeout)
                `uvm_warning("TEST_TIMEOUT", $sformatf("%s: kernel timeout! (expected)", label))
            else
                `uvm_error("TEST_TIMEOUT", $sformatf("%s: kernel timeout!", label))
        end
    endtask

    virtual task clear_start();
        host_ctrl_item h = host_ctrl_item::type_id::create("h");
        h.is_start_clear = 1;
        p_sequencer.host_seqr.execute_item(h);
    endtask
endclass
