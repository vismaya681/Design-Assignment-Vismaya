module dff_tb(

    );
    reg d_tb,rst_tb,clk_tb;
    wire q_tb,qbar_tb;
    dff dut(d_tb,rst_tb,clk_tb,q_tb,qbar_tb);
    initial
    begin
    {d_tb,rst_tb,clk_tb}=0;
    end 
    always #5 clk_tb= ~ clk_tb;
    initial
    begin
    rst_tb=1;
    #10;
    rst_tb=0;
    d_tb=1;
    #10;
    d_tb=0;
    #10;
    d_tb=1;
    #10;
    end
    
    
    
    
endmodule

