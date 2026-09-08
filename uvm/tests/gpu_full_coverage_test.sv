class gpu_full_coverage_seq extends gpu_base_vseq;
    `uvm_object_utils(gpu_full_coverage_seq)
    
    int num_threads = 1;
    
    function new(string name = "gpu_full_coverage_seq");
        super.new(name);
    endfunction
    
    virtual task set_thread_count(int thread_count);
        host_ctrl_item h = host_ctrl_item::type_id::create("h");
        h.is_write = 1; h.data = thread_count;
        p_sequencer.host_seqr.execute_item(h);
    endtask

    virtual task start_kernel();
        host_ctrl_item h = host_ctrl_item::type_id::create("h2");
        h.is_write = 0;
        p_sequencer.host_seqr.execute_item(h);
    endtask

    virtual task body();
        logic [15:0] cov_prog[$] = '{
            16'h9110, 16'h9250,
            16'h3312, 16'h4412, 16'h5512, 16'h6612,
            16'h2012,
            16'h1000,
            16'h0000,
            16'h9100, 16'h9205, 16'h8012,
            16'h7010,
            16'hF000
        };
        
        set_thread_count(num_threads);
        
        load_program(cov_prog);
        
        start_kernel();
    endtask
endclass

class gpu_full_coverage_test extends gpu_base_test;
    `uvm_component_utils(gpu_full_coverage_test)

    function new(string name = "gpu_full_coverage_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_full_coverage_seq seq;
        int tcounts[] = '{1, 2, 4, 5, 8, 9};
        
        phase.raise_objection(this);
        start_clk_and_reset();

        foreach (tcounts[i]) begin
            `uvm_info("TEST", $sformatf("=== Coverage Iteration: %0d threads ===", tcounts[i]), UVM_LOW)
            seq = gpu_full_coverage_seq::type_id::create("seq");
            seq.num_threads = tcounts[i];
            
            seq.start(env.v_seqr, null, -1, 0);

            fork
                env.done_ag.monitor.wait_for_done();
                begin
                    #(env.cfg.watchdog_timeout_ns * 1ns);
                    `uvm_error("TEST", "Kernel timeout!")
                end
            join_any
            disable fork;
            
            begin
                host_ctrl_item h_clr = host_ctrl_item::type_id::create("h_clr");
                h_clr.is_start_clear = 1;
                env.host_agent.sequencer.execute_item(h_clr);
            end
            
            begin
                rst_item r_item = rst_item::type_id::create("r_item");
                r_item.duration_ns = 20;
                env.rst_ag.sequencer.execute_item(r_item);
            end
            #50ns;
        end

        `uvm_info("TEST", "Full coverage test finished successfully!", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
