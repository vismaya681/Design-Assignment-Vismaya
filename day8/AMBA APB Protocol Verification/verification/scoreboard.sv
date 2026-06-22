class scoreboard;
    mailbox #(apb_transaction) mon2scb;
    bit [31:0] ref_mem [32];
    
    // NEW: Counter to track finished transactions
    int trans_count = 0; 

    function new(mailbox #(apb_transaction) mon2scb);
        this.mon2scb = mon2scb;
        foreach(ref_mem[i]) ref_mem[i] = 0; 
    endfunction

    task run();
        forever begin
            apb_transaction tr;
            mon2scb.get(tr);

            if (tr.paddr < 32) begin
                if (tr.pslverr !== 0) 
                    $error("[SCB FAIL] pslverr asserted on VALID address %0d", tr.paddr);

                if (tr.pwrite) begin
                    ref_mem[tr.paddr] = tr.pwdata;
                    $display("[SCB PASS] Wrote %0h to Address %0d", tr.pwdata, tr.paddr);
                end else begin
                    if (tr.prdata === ref_mem[tr.paddr])
                        $display("[SCB PASS] Read %0h from Address %0d MATCHES!", tr.prdata, tr.paddr);
                    else
                        $error("[SCB FAIL] Read Addr %0d. Expected: %0h, Got: %0h", tr.paddr, ref_mem[tr.paddr], tr.prdata);
                end
            end else begin
                if (tr.pslverr === 1 && tr.prdata === 32'hDEAD_BEEF)
                    $display("[SCB PASS] Out of bounds correctly flagged! Addr: %0d, pslverr: 1, prdata: DEAD_BEEF", tr.paddr);
                else
                    $error("[SCB FAIL] Out of bounds logic failed! Addr: %0d, pslverr: %0b, prdata: %0h", tr.paddr, tr.pslverr, tr.prdata);
            end
            
            // NEW: Increment the counter after checking
            trans_count++; 
        end
    endtask
endclass
