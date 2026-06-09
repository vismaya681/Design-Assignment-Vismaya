module srff_tb(

    );
    reg s_tb,r_tb,rst_tb,clk_tb;
    wire q_tb,qbar_tb;
    srff dut(s_tb,r_tb,rst_tb,clk_tb,q_tb,qbar_tb);
    
    initial
    begin
    {s_tb,r_tb,rst_tb,clk_tb}=0;
    end
    always #5 clk_tb= ~ clk_tb;
    initial
    begin
    rst_tb=1;
    #10;
    rst_tb=0;
    s_tb=0;
    r_tb=0;
    #10;
    s_tb=0;
    r_tb=1;
    #10;
    s_tb=1;
    r_tb=0;
    #10;
    s_tb=1;
    r_tb=1;
    
    end
    
endmodule
