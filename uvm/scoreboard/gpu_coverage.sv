class gpu_coverage extends uvm_component;
    `uvm_component_utils(gpu_coverage)

    uvm_analysis_imp_host     #(host_ctrl_item, gpu_coverage) host_export;
    uvm_analysis_imp_data_mem #(memory_item,    gpu_coverage) data_mem_export;
    uvm_analysis_imp_prog_mem #(memory_item,    gpu_coverage) prog_mem_export;

    virtual gpu_dut_probe_if probe_vif;

    int          sampled_thread_count;
    logic [3:0]  sampled_opcode;
    logic [7:0]  sampled_mem_addr;
    logic [7:0]  sampled_mem_data;
    bit          sampled_is_read;
    bit          sampled_is_write;
    int          kernel_count;
    bit          kernel_active;

    logic [2:0]  cur_core_state;
    logic [2:0]  cur_fetcher_state;
    logic [7:0]  cur_lsu_states;
    logic [11:0] cur_ctrl_state;
    logic [3:0]  cur_opcode;
    logic        cur_pc_mux;
    logic        cur_alu_output_mux;
    logic [1:0]  cur_alu_op;
    logic [2:0]  cur_nzp_reg;
    logic [2:0]  cur_decoded_nzp;
    logic        cur_nzp_write_enable;
    logic [7:0]  cur_rs, cur_rt;
    logic [7:0]  cur_alu_out;
    logic [3:0]  cur_rd_addr;
    logic        cur_reg_write_enable;
    logic [7:0]  cur_block_id;

    covergroup cg_kernel_config;
        cp_thread_count: coverpoint sampled_thread_count {
            bins single       = {1};
            bins partial_blk  = {[2:3]};
            bins one_full_blk = {4};
            bins multi_partial = {[5:7]};
            bins two_full_blk = {8};
            bins many_threads = {[9:$]};
        }
    endgroup

    covergroup cg_isa;
        cp_opcode: coverpoint sampled_opcode {
            bins nop   = {4'h0};
            bins br    = {4'h1};
            bins cmp   = {4'h2};
            bins add   = {4'h3};
            bins sub   = {4'h4};
            bins mul   = {4'h5};
            bins div   = {4'h6};
            bins ldr   = {4'h7};
            bins str   = {4'h8};
            bins cnst  = {4'h9};
            bins ret   = {4'hF};
            bins unused_a = {4'hA};
            bins unused_b = {4'hB};
            bins unused_c = {4'hC};
            bins unused_d = {4'hD};
            bins unused_e = {4'hE};
        }
    endgroup

    covergroup cg_data_mem;
        cp_addr: coverpoint sampled_mem_addr {
            bins low_range   = {[8'h00:8'h0F]};
            bins mid_range   = {[8'h10:8'h7F]};
            bins high_range  = {[8'h80:8'hFE]};
            bins boundary    = {8'hFF};
        }

        cp_data: coverpoint sampled_mem_data {
            bins zero       = {8'h00};
            bins lo_vals    = {[8'h01:8'h0F]};
            bins mid_vals   = {[8'h10:8'h7F]};
            bins hi_vals    = {[8'h80:8'hFE]};
            bins max_val    = {8'hFF};
        }

        cp_direction: coverpoint sampled_is_read {
            bins read  = {1};
            bins write = {0};
        }

        cx_addr_dir: cross cp_addr, cp_direction;
    endgroup

    covergroup cg_cross;
        cp_opcode: coverpoint sampled_opcode {
            bins arithmetic = {4'h3, 4'h4, 4'h5, 4'h6};
            bins memory     = {4'h7, 4'h8};
            bins control    = {4'h1, 4'h2};
            bins other      = {4'h0, 4'h9, 4'hF};
        }

        cp_threads: coverpoint sampled_thread_count {
            bins low  = {[1:4]};
            bins high = {[5:$]};
        }

        cx_opcode_threads: cross cp_opcode, cp_threads;
    endgroup

    covergroup cg_alu_boundary;
        cp_alu_op: coverpoint cur_alu_op {
            bins add = {2'b00};
            bins sub = {2'b01};
            bins mul = {2'b10};
            bins div = {2'b11};
        }

        cp_operand_boundary: coverpoint cur_rs {
            bins zero      = {8'h00};
            bins one       = {8'h01};
            bins mid       = {[8'h02:8'h7E]};
            bins s127      = {8'h7F};
            bins s128      = {8'h80};
            bins max       = {8'hFF};
        }

        cp_div_by_zero: coverpoint ((cur_alu_op == 2'b11) && (cur_rt == 8'h00)) iff (cur_alu_op == 2'b11) {
            bins div_normal = {0};
            bins div_zero   = {1};
        }

        cx_op_operand: cross cp_alu_op, cp_operand_boundary;
    endgroup

    covergroup cg_cmp;
        cp_cmp_result: coverpoint cur_alu_out[2:0] iff (cur_nzp_write_enable && cur_alu_output_mux) {
            bins negative  = {3'b100};
            bins zero      = {3'b010};
            bins positive  = {3'b001};
            bins none      = {3'b000};
        }
    endgroup

    covergroup cg_branch;
        cp_nzp_cond: coverpoint cur_decoded_nzp iff (cur_pc_mux) {
            bins br_n       = {3'b100};
            bins br_z       = {3'b010};
            bins br_p       = {3'b001};
            bins br_nz      = {3'b110};
            bins br_np      = {3'b101};
            bins br_zp      = {3'b011};
            bins br_nzp     = {3'b111};
        }

        cp_taken: coverpoint ((cur_nzp_reg & cur_decoded_nzp) != 3'b000) iff (cur_pc_mux) {
            bins not_taken = {0};
            bins taken     = {1};
        }

        cx_cond_taken: cross cp_nzp_cond, cp_taken;
    endgroup

    covergroup cg_registers;
        cp_rd_addr: coverpoint cur_rd_addr iff (cur_reg_write_enable) {
            bins free_regs   = {[0:12]};
            bins prot_blkidx = {13};
            bins prot_blkdim = {14};
            bins prot_thridx = {15};
        }
    endgroup

    covergroup cg_core_fsm;
        cp_state: coverpoint cur_core_state {
            bins idle    = {3'b000};
            bins fetch   = {3'b001};
            bins decode  = {3'b010};
            bins request = {3'b011};
            bins wait_st = {3'b100};
            bins execute = {3'b101};
            bins update  = {3'b110};
            bins done    = {3'b111};
        }
    endgroup

    covergroup cg_fetcher_fsm;
        cp_state: coverpoint cur_fetcher_state {
            bins idle     = {3'b000};
            bins fetching = {3'b001};
            bins fetched  = {3'b010};
        }
    endgroup

    covergroup cg_lsu_fsm;
        cp_state: coverpoint cur_lsu_states[1:0] {
            bins idle       = {2'b00};
            bins requesting = {2'b01};
            bins waiting    = {2'b10};
            bins done       = {2'b11};
        }
    endgroup

    covergroup cg_controller_fsm;
        cp_state: coverpoint cur_ctrl_state[2:0] {
            bins idle           = {3'b000};
            bins read_waiting   = {3'b010};
            bins write_waiting  = {3'b011};
            bins read_relaying  = {3'b100};
            bins write_relaying = {3'b101};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        host_export     = new("host_export", this);
        data_mem_export = new("data_mem_export", this);
        prog_mem_export = new("prog_mem_export", this);

        if (!uvm_config_db#(virtual gpu_dut_probe_if)::get(this, "", "probe_vif", probe_vif))
            `uvm_fatal("COV", "Could not get probe_vif")

        cg_kernel_config    = new();
        cg_isa              = new();
        cg_data_mem         = new();
        cg_cross            = new();
        cg_alu_boundary     = new();
        cg_cmp              = new();
        cg_branch           = new();
        cg_registers        = new();
        cg_core_fsm         = new();
        cg_fetcher_fsm      = new();
        cg_lsu_fsm          = new();
        cg_controller_fsm   = new();

        kernel_count  = 0;
        kernel_active = 0;
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            forever begin
                @(posedge probe_vif.clk);
                cur_core_state     = probe_vif.core_state;
                cur_fetcher_state  = probe_vif.fetcher_state;
                cur_lsu_states     = probe_vif.lsu_states;
                cur_ctrl_state     = probe_vif.ctrl_state;
                cur_opcode         = probe_vif.opcode;
                cur_pc_mux         = probe_vif.pc_mux;
                cur_alu_output_mux = probe_vif.alu_output_mux;
                cur_alu_op         = probe_vif.alu_op;
                cur_nzp_reg        = probe_vif.nzp_reg;
                cur_decoded_nzp    = probe_vif.decoded_nzp;
                cur_nzp_write_enable = probe_vif.nzp_write_enable;
                cur_rs             = probe_vif.rs0;
                cur_rt             = probe_vif.rt0;
                cur_alu_out        = probe_vif.alu_out0;
                cur_rd_addr        = probe_vif.rd_addr;
                cur_reg_write_enable = probe_vif.reg_write_enable;
                cur_block_id       = probe_vif.block_id0;

                cg_core_fsm.sample();
                cg_fetcher_fsm.sample();
                cg_lsu_fsm.sample();
                cg_controller_fsm.sample();

                if (cur_pc_mux) cg_branch.sample();

                if (cur_alu_output_mux && cur_nzp_write_enable) cg_cmp.sample();

                if (!cur_alu_output_mux) cg_alu_boundary.sample();

                if (cur_reg_write_enable && cur_core_state == 3'b110) cg_registers.sample();
            end
        join_none
    endtask

    virtual function void write_host(host_ctrl_item t);
        if (t.is_write) begin
            sampled_thread_count = t.data;
            cg_kernel_config.sample();
            `uvm_info("COV", $sformatf("Sampled thread_count=%0d, kernel_cfg_cov=%.1f%%",
                sampled_thread_count, cg_kernel_config.get_coverage()), UVM_HIGH)
        end else begin
            kernel_count++;
            kernel_active = 1;
        end
    endfunction

    virtual function void write_prog_mem(memory_item t);
        if (t.op == READ) begin
            sampled_opcode = t.data[15:12];
            cg_isa.sample();
            if (sampled_thread_count > 0)
                cg_cross.sample();
        end
    endfunction

    virtual function void write_data_mem(memory_item t);
        sampled_mem_addr = t.addr;
        sampled_mem_data = t.data[7:0];
        sampled_is_read  = (t.op == READ);
        sampled_is_write = (t.op == WRITE);
        cg_data_mem.sample();
    endfunction

    function void reset();
        kernel_active = 0;
    endfunction

    virtual function void report_phase(uvm_phase phase);
        real total_cov;
        super.report_phase(phase);

        total_cov = (cg_kernel_config.get_coverage() +
                     cg_isa.get_coverage() +
                     cg_data_mem.get_coverage() +
                     cg_cross.get_coverage() +
                     cg_alu_boundary.get_coverage() +
                     cg_cmp.get_coverage() +
                     cg_branch.get_coverage() +
                     cg_registers.get_coverage() +
                     cg_core_fsm.get_coverage() +
                     cg_fetcher_fsm.get_coverage() +
                     cg_lsu_fsm.get_coverage() +
                     cg_controller_fsm.get_coverage()) / 12.0;

        `uvm_info("COV", "============================================", UVM_LOW)
        `uvm_info("COV", "        COVERAGE SUMMARY", UVM_LOW)
        `uvm_info("COV", "============================================", UVM_LOW)
        `uvm_info("COV", $sformatf("  Kernel config  : %6.1f%%", cg_kernel_config.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  ISA opcodes    : %6.1f%%", cg_isa.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  Data memory    : %6.1f%%", cg_data_mem.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  Cross coverage : %6.1f%%", cg_cross.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  ALU boundary   : %6.1f%%", cg_alu_boundary.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  CMP/NZP result : %6.1f%%", cg_cmp.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  Branch NZP     : %6.1f%%", cg_branch.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  Registers      : %6.1f%%", cg_registers.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  Core FSM       : %6.1f%%", cg_core_fsm.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  Fetcher FSM    : %6.1f%%", cg_fetcher_fsm.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  LSU FSM        : %6.1f%%", cg_lsu_fsm.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("  Controller FSM : %6.1f%%", cg_controller_fsm.get_coverage()), UVM_LOW)
        `uvm_info("COV", "--------------------------------------------", UVM_LOW)
        `uvm_info("COV", $sformatf("  AVERAGE        : %6.1f%%", total_cov), UVM_LOW)
        `uvm_info("COV", $sformatf("  Kernels run    : %0d", kernel_count), UVM_LOW)
        `uvm_info("COV", "============================================", UVM_LOW)
    endfunction
endclass
