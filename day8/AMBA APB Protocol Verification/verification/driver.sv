class driver;
    virtual apb_if vif;
    // FIX: Parameterized mailbox for Vivado XSim
    mailbox #(apb_transaction) gen2drv;

    function new(virtual apb_if vif, mailbox #(apb_transaction) gen2drv);
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction

    task run();
        vif.psel <= 0;
        vif.penable <= 0;
        vif.pwrite <= 0;
        vif.paddr <= 0;
        vif.pwdata <= 0;

        wait(vif.presetn == 1); 

        forever begin
            apb_transaction tr;
            gen2drv.get(tr);
            
            @(posedge vif.pclk);
            vif.psel    <= 1;
            vif.penable <= 0;
            vif.paddr   <= tr.paddr;
            vif.pwrite  <= tr.pwrite;
            if (tr.pwrite) vif.pwdata <= tr.pwdata;

            @(posedge vif.pclk);
            vif.penable <= 1;

            do begin
                @(posedge vif.pclk);
            end while (vif.pready !== 1);

            vif.psel    <= 0;
            vif.penable <= 0;
        end
    endtask
endclass
