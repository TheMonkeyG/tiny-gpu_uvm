interface gpu_dut_probe_if(input logic clk);
    logic [2:0]  core_state;
    logic [2:0]  fetcher_state;
    logic [7:0]  lsu_states;
    logic [11:0] ctrl_state;
    logic [3:0]  opcode;
    logic        pc_mux;
    logic        alu_output_mux;
    logic [1:0]  alu_op;
    logic [2:0]  decoded_nzp;
    logic        nzp_write_enable;
    logic [3:0]  rd_addr;
    logic        reg_write_enable;
    logic [2:0]  nzp_reg;
    logic [7:0]  rs0, rt0, alu_out0;
    logic [7:0]  block_id0;
endinterface
