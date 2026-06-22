class generator;
    // FIX: Parameterized mailbox for Vivado XSim
    mailbox #(apb_transaction) gen2drv;
    int num_transactions = 20;

    function new(mailbox #(apb_transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    task run();
        apb_transaction tr;
        
        // 1. Directed Test: Write to Address 4
        tr = new();
        tr.paddr = 4; tr.pwrite = 1; tr.pwdata = 32'hAAAA_BBBB;
        gen2drv.put(tr);
        
        // 2. Directed Test: Read from Address 4
        tr = new();
        tr.paddr = 4; tr.pwrite = 0;
        gen2drv.put(tr);

        // 3. Random Tests
        for (int i = 0; i < num_transactions; i++) begin
            tr = new();
            // FIX: Added '1' as the first argument for $fatal
            if (!tr.randomize()) $fatal(1, "Randomization failed!");
            gen2drv.put(tr);
        end
    endtask
endclass
