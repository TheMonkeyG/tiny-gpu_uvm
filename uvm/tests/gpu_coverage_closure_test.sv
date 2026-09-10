
class gpu_coverage_closure_seq extends gpu_base_vseq;
    `uvm_object_utils(gpu_coverage_closure_seq)

    int num_threads = 1;
    int prog_sel = 1;

    function new(string name = "gpu_coverage_closure_seq");
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

    function automatic logic [15:0] br_word(logic [2:0] mask, logic [7:0] imm);
        return 16'h1000 | (mask << 9) | imm;
    endfunction

    function void get_branch_prog_a(ref logic [15:0] prog[$]);
        prog = '{
            16'h9101, 16'h9200,
            16'h2012, br_word(3'b001, 5),  16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b010, 9),  16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b100, 13), 16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b011, 17), 16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b101, 21), 16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b110, 25), 16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b111, 29), 16'h90EE, 16'h90DD,
            16'hF000
        };
    endfunction

    function void get_branch_prog_b(ref logic [15:0] prog[$]);
        prog = '{
            16'h9100, 16'h9201,
            16'h2012, br_word(3'b001, 5),  16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b010, 9),  16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b100, 13), 16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b011, 17), 16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b101, 21), 16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b110, 25), 16'h90EE, 16'h90DD,
            16'h2012, br_word(3'b111, 29), 16'h90EE, 16'h90DD,
            16'hF000
        };
    endfunction

    function void get_branch_prog_c(ref logic [15:0] prog[$]);
        prog = '{
            br_word(3'b111, 4),
            br_word(3'b101, 4),
            16'h0000, 16'h0000,
            16'h9105, 16'h9205,
            16'h2012,
            br_word(3'b010, 10),
            16'h90EE, 16'h0000,
            16'hF000
        };
    endfunction

    function void get_alu_prog(ref logic [15:0] prog[$]);
        int alu_pairs[10][2] = '{
            '{8'h00, 8'h00}, '{8'h01, 8'h01}, '{8'h7F, 8'h80},
            '{8'h80, 8'hFF}, '{8'hFF, 8'hFF}, '{8'hC8, 8'hC8},
            '{8'h00, 8'h01}, '{8'h14, 8'h14}, '{8'h05, 8'h00},
            '{8'hFF, 8'h07}
        };
        prog.delete();
        foreach (alu_pairs[i]) begin
            prog.push_back(16'h9100 | alu_pairs[i][0]);
            prog.push_back(16'h9200 | alu_pairs[i][1]);
            prog.push_back(16'h3312);
            prog.push_back(16'h4412);
            prog.push_back(16'h5512);
            prog.push_back(16'h6612);
        end
        prog.push_back(16'hF000);
    endfunction

    function void get_prot_prog(ref logic [15:0] prog[$]);
        prog = '{
            16'h9105, 16'h9205,
            16'h2012,
            16'h9D55,
            16'h9E66,
            16'h9F77,
            16'hA000,
            16'hB123,
            16'hC456,
            16'hD789,
            16'hEABC,
            16'h0000,
            16'hF000
        };
    endfunction

    virtual task body();
        logic [15:0] prog[$];

        set_thread_count(num_threads);

        case (prog_sel)
            1: get_branch_prog_a(prog);
            2: get_branch_prog_b(prog);
            3: get_branch_prog_c(prog);
            4: get_alu_prog(prog);
            5: get_prot_prog(prog);
        endcase

        load_program(prog);
        start_kernel();
    endtask
endclass


class gpu_coverage_closure_test extends gpu_base_test;
    `uvm_component_utils(gpu_coverage_closure_test)

    function new(string name = "gpu_coverage_closure_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpu_coverage_closure_seq seq;
        string labels[5] = '{"branch A (positive)", "branch B (negative)",
                            "branch C (zero+reset-nzp)", "ALU boundary",
                            "protect+unused"};

        phase.raise_objection(this);
        start_clk_and_reset();

        `uvm_info("TEST", "=== Coverage closure: 5 kernels (branch A/B/C, ALU, protect+unused) ===", UVM_LOW)

        for (int k = 1; k <= 5; k++) begin
            `uvm_info("TEST", $sformatf("--- Kernel %0d: %s ---", k, labels[k-1]), UVM_LOW)
            seq = gpu_coverage_closure_seq::type_id::create("seq");
            seq.num_threads = 1;
            seq.prog_sel = k;
            seq.start(env.v_seqr, null, -1, 0);

            fork
                env.done_ag.monitor.wait_for_done();
                begin
                    #(env.cfg.watchdog_timeout_ns * 1ns);
                    `uvm_error("TEST", $sformatf("%s: kernel timeout!", labels[k-1]))
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

        `uvm_info("TEST", "Coverage closure test finished successfully!", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass