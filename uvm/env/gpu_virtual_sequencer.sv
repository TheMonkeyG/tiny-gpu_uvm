
class gpu_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(gpu_virtual_sequencer)

    uvm_sequencer #(host_ctrl_item) host_seqr;
    uvm_sequencer #(memory_item)    prog_seqr;
    uvm_sequencer #(memory_item)    data_seqr;

    done_monitor done_mon;
    int unsigned watchdog_timeout_ns = 2_000_000;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
