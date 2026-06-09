module encoder4by2_tb(

    );
    reg [3:0]D_tb;
    wire [1:0]b_tb;
    
    encoder4by2 dut(D_tb,b_tb);
    initial 
    begin
    {D_tb}=0;
    end
    initial 
    begin
    D_tb=4'b0001;
    #1;
    D_tb=4'b0010;
    #1;
    D_tb=4'b0100;
    #1;
    D_tb=4'b1000;
    #1;
    
    end 
    
endmodule

