`timescale 1ns / 1ns

module gpu_tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import clk_pkg::*;
    import rst_pkg::*;
    import done_pkg::*;
    import host_ctrl_pkg::*;
    import memory_pkg::*;
    import gpu_env_pkg::*;
    import gpu_test_pkg::*;

    clk_agent_if  clk_if();
    rst_agent_if  rst_if(clk_if.clk);

    wire clk   = clk_if.clk;
    wire reset = rst_if.reset;

    host_ctrl_if h_if(clk, reset);
    memory_if #(8, 16, 1) p_if(clk, reset);
    memory_if #(8, 8, 4)  d_if(clk, reset);
    done_agent_if done_if(clk, reset);

    localparam int PM_CH = 1;
    localparam int PM_AB = 8;
    localparam int PM_DB = 16;
    localparam int DM_CH = 4;
    localparam int DM_AB = 8;
    localparam int DM_DB = 8;

    wire [PM_CH-1:0]                 w_pm_rvalid;
    wire [PM_CH*PM_AB-1:0]         w_pm_raddr;
    wire [PM_CH-1:0]               w_pm_rready;
    wire [PM_CH*PM_DB-1:0]         w_pm_rdata;
    wire [DM_CH-1:0]               w_dm_rvalid;
    wire [DM_CH*DM_AB-1:0]         w_dm_raddr;
    wire [DM_CH-1:0]               w_dm_rready;
    wire [DM_CH*DM_DB-1:0]         w_dm_rdata;
    wire [DM_CH-1:0]               w_dm_wvalid;
    wire [DM_CH*DM_AB-1:0]         w_dm_waddr;
    wire [DM_CH*DM_DB-1:0]         w_dm_wdata;
    wire [DM_CH-1:0]               w_dm_wready;

    gpu #(
        .DATA_MEM_ADDR_BITS(8),
        .DATA_MEM_DATA_BITS(8),
        .DATA_MEM_NUM_CHANNELS(4),
        .PROGRAM_MEM_ADDR_BITS(8),
        .PROGRAM_MEM_DATA_BITS(16),
        .PROGRAM_MEM_NUM_CHANNELS(1)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(h_if.start),
        .done(h_if.done),
        .device_control_write_enable(h_if.device_control_write_enable),
        .device_control_data(h_if.device_control_data),

        .program_mem_read_valid(w_pm_rvalid),
        .program_mem_read_address(w_pm_raddr),
        .program_mem_read_ready(w_pm_rready),
        .program_mem_read_data(w_pm_rdata),

        .data_mem_read_valid(w_dm_rvalid),
        .data_mem_read_address(w_dm_raddr),
        .data_mem_read_ready(w_dm_rready),
        .data_mem_read_data(w_dm_rdata),
        .data_mem_write_valid(w_dm_wvalid),
        .data_mem_write_address(w_dm_waddr),
        .data_mem_write_data(w_dm_wdata),
        .data_mem_write_ready(w_dm_wready)
    );

    assign done_if.done = h_if.done;

    gpu_dut_probe_if probe_if(clk);
    assign probe_if.core_state     = dut.cores[0].core_instance.core_state;
    assign probe_if.fetcher_state  = dut.cores[0].core_instance.fetcher_state;
    assign probe_if.lsu_states     = dut.cores[0].core_instance.lsu_state;
    assign probe_if.ctrl_state     = dut.data_memory_controller.controller_state;
    assign probe_if.opcode         = dut.cores[0].core_instance.instruction[15:12];
    assign probe_if.pc_mux         = dut.cores[0].core_instance.decoded_pc_mux;
    assign probe_if.alu_output_mux = dut.cores[0].core_instance.decoded_alu_output_mux;
    assign probe_if.alu_op         = dut.cores[0].core_instance.decoded_alu_arithmetic_mux;
    assign probe_if.decoded_nzp    = dut.cores[0].core_instance.decoded_nzp;
    assign probe_if.nzp_write_enable = dut.cores[0].core_instance.decoded_nzp_write_enable;
    assign probe_if.rd_addr        = dut.cores[0].core_instance.decoded_rd_address;
    assign probe_if.reg_write_enable = dut.cores[0].core_instance.decoded_reg_write_enable;
    assign probe_if.nzp_reg        = dut.cores[0].core_instance.threads[0].pc_instance.nzp;
    assign probe_if.rs0            = dut.cores[0].core_instance.rs[0];
    assign probe_if.rt0            = dut.cores[0].core_instance.rt[0];
    assign probe_if.alu_out0       = dut.cores[0].core_instance.alu_out[0];
    assign probe_if.block_id0      = dut.core_block_id[0];

    assign p_if.read_valid = w_pm_rvalid;
    assign p_if.read_address = w_pm_raddr;
    assign w_pm_rready = p_if.read_ready;
    assign w_pm_rdata = p_if.read_data;

    assign d_if.read_valid = w_dm_rvalid;
    assign d_if.read_address = w_dm_raddr;
    assign w_dm_rready = d_if.read_ready;
    assign w_dm_rdata = d_if.read_data;

    assign d_if.write_valid = w_dm_wvalid;
    assign d_if.write_address = w_dm_waddr;
    assign d_if.write_data = w_dm_wdata;
    assign w_dm_wready = d_if.write_ready;

    initial begin
        uvm_config_db#(virtual clk_agent_if)::set(null, "*", "clk_vif", clk_if);
        uvm_config_db#(virtual rst_agent_if)::set(null, "*", "rst_vif", rst_if);
        uvm_config_db#(virtual done_agent_if)::set(null, "*", "done_vif", done_if);
        uvm_config_db#(virtual host_ctrl_if)::set(null, "*", "h_vif", h_if);
        uvm_config_db#(virtual memory_if#(8,16,1))::set(null, "*", "p_vif", p_if);
        uvm_config_db#(virtual memory_if#(8,8,4))::set(null, "*", "d_vif", d_if);
        uvm_config_db#(virtual gpu_dut_probe_if)::set(null, "*", "probe_vif", probe_if);
        
        run_test();
    end
endmodule
