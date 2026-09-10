class done_monitor extends uvm_monitor;
    `uvm_component_utils(done_monitor)

    virtual done_agent_if vif;
    uvm_analysis_port #(done_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        wait (!$isunknown(vif.done));
        fork
            forever begin
                done_item item;
                @(posedge vif.done or negedge vif.done);
                if (vif.reset) continue;
                item = done_item::type_id::create("item");
                item.value = vif.done;
                item.timestamp = $time;
                ap.write(item);
            end
        join_none
    endtask

    task wait_for_done();
        wait (vif.reset === 1'b0 && vif.done === 1'b1);
    endtask
endclass
