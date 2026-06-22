module tb_top;
    logic pclk;
    logic presetn;

    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk; 
    end

    initial begin
        presetn = 0;
        #20 presetn = 1;
    end

    apb_if vif(pclk, presetn);

    apb_slave dut (
        .pclk(vif.pclk),
        .presetn(vif.presetn),
        .paddr(vif.paddr),
        .psel(vif.psel),
        .penable(vif.penable),
        .pwrite(vif.pwrite),
        .pwdata(vif.pwdata),
        .pready(vif.pready),
        .pslverr(vif.pslverr),
        .prdata(vif.prdata)
    );

    initial begin
        environment env;
        env = new(vif);
        
        $display("==================================================");
        $display("   STARTING APB SLAVE VERIFICATION   ");
        $display("==================================================");
        
        env.run();
        
        #50;
        
        $display("==================================================");
        $display("   TESTBENCH COMPLETE   ");
        $display("==================================================");
        $finish;
    end
endmodule
