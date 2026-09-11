package gpu_seq_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import gpu_isa_pkg::*;
    import gpu_program_lib_pkg::*;
    import host_ctrl_pkg::*;
    import memory_pkg::*;
    import gpu_env_pkg::*;

    `include "gpu_base_vseq.sv"
    `include "gpu_kernel_seq.sv"
endpackage
