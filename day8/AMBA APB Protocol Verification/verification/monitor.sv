class monitor;
    virtual apb_if vif;
    // FIX: Parameterized mailbox for Vivado XSim
    mailbox #(apb_transaction) mon2scb;

    function new(virtual apb_if vif, mailbox #(apb_transaction) mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run();
        forever begin
            @(posedge vif.pclk);
            if (vif.psel && vif.penable && vif.pready) begin
                apb_transaction tr = new();
                tr.paddr   = vif.paddr;
                tr.pwrite  = vif.pwrite;
                tr.pwdata  = vif.pwdata;
                tr.prdata  = vif.prdata;
                tr.pslverr = vif.pslverr;
                mon2scb.put(tr);
            end
        end
    endtask
endclass
