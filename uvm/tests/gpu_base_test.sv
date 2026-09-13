class gpu_base_test extends uvm_test;
    `uvm_component_utils(gpu_base_test)

    gpu_env     env;
    gpu_env_cfg cfg;

    function new(string name = "gpu_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        cfg = gpu_env_cfg::type_id::create("cfg");
        configure_env(cfg);

        uvm_config_db#(gpu_env_cfg)::set(this, "env", "cfg", cfg);

        env = gpu_env::type_id::create("env", this);
    endfunction

    virtual function void configure_env(gpu_env_cfg cfg);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (!uvm_config_db#(virtual clk_agent_if)::get(this, "", "clk_vif", env.clk_ag.driver.vif))
            `uvm_fatal("TEST", "Could not get clk_vif")

        if (!uvm_config_db#(virtual rst_agent_if)::get(this, "", "rst_vif", env.rst_ag.driver.vif))
            `uvm_fatal("TEST", "Could not get rst_vif")
        env.rst_ag.monitor.vif = env.rst_ag.driver.vif;

        if (!uvm_config_db#(virtual done_agent_if)::get(this, "", "done_vif", env.done_ag.monitor.vif))
            `uvm_fatal("TEST", "Could not get done_vif")

        if (!uvm_config_db#(virtual host_ctrl_if)::get(this, "", "h_vif", env.host_agent.driver.vif))
            `uvm_fatal("TEST", "Could not get h_vif")
        env.host_agent.monitor.vif = env.host_agent.driver.vif;

        if (!uvm_config_db#(virtual memory_if#(8,16,1))::get(this, "", "p_vif", env.prog_mem_agent.driver.vif))
            `uvm_fatal("TEST", "Could not get p_vif")
        env.prog_mem_agent.monitor.vif = env.prog_mem_agent.driver.vif;

        if (!uvm_config_db#(virtual memory_if#(8,8,4))::get(this, "", "d_vif", env.data_mem_agent.driver.vif))
            `uvm_fatal("TEST", "Could not get d_vif")
        env.data_mem_agent.monitor.vif = env.data_mem_agent.driver.vif;
    endfunction

    virtual task start_clk_and_reset();
        clk_item c_item;
        rst_item r_item;

        c_item = clk_item::type_id::create("c_item");
        c_item.period_ns = 10;
        env.clk_ag.sequencer.execute_item(c_item);

        r_item = rst_item::type_id::create("r_item");
        r_item.duration_ns = 20;
        env.rst_ag.sequencer.execute_item(r_item);
    endtask

    virtual function gpu_kernel_seq new_matadd(int unsigned threads, bit random_data = 0);
        gpu_kernel_seq seq = gpu_kernel_seq::type_id::create("seq");
        seq.num_threads = threads;
        seq.data_base = 0;
        gpu_program_lib::matadd(seq.prog, seq.data_bytes, random_data);
        return seq;
    endfunction

    virtual task launch_and_wait(gpu_kernel_seq seq, string label);
        seq.start(env.v_seqr, null, -1, 0);
        seq.wait_kernel_done(label);
        #(env.cfg.post_done_drain_ns * 1ns);
        seq.clear_start();
    endtask

    virtual task launch_and_wait_checked(gpu_kernel_seq seq, string label);
        real t_start, t_end;
        seq.start(env.v_seqr, null, -1, 0);
        t_start = $realtime;
        fork
            begin
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
        seq.clear_start();
    endtask

    virtual task inject_reset(int duration_ns);
        rst_item r = rst_item::type_id::create("r");
        r.duration_ns = duration_ns;
        env.rst_ag.sequencer.execute_item(r);
    endtask

    virtual task host_clear();
        host_ctrl_item h = host_ctrl_item::type_id::create("h");
        h.is_start_clear = 1;
        env.host_agent.sequencer.execute_item(h);
    endtask

    virtual task post_kernel_cleanup();
        host_clear();
        if (env.cfg.en_coverage) env.coverage_col.reset();
        inject_reset(20);
        #50ns;
    endtask

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("TEST", "Base test started", UVM_LOW)
        start_clk_and_reset();
        #100ns;
        `uvm_info("TEST", "Base test finished", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass
