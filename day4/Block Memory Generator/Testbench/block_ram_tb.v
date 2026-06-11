
module block_ram_tb(

    );
    reg clk_tb,arstn_tb,wrenb_tb;
    reg [7:0] wr_address_tb;
    reg [7:0] rd_address_tb;
    reg [7:0] data_in_tb;
    wire [7:0] data_out_tb;
    
    block_ram dut(clk_tb,arstn_tb,wrenb_tb,wr_address_tb,rd_address_tb,data_in_tb,data_out_tb);
    
    initial 
    begin
    {clk_tb,arstn_tb,wrenb_tb,wr_address_tb,rd_address_tb,data_in_tb}=0;
    end
    
    always #5 clk_tb=~clk_tb;
    
    initial
    begin
    #20;
    arstn_tb=1;
    #10;
    
    //writing data
    wrenb_tb=1;
    wr_address_tb=3'b000;
    data_in_tb=8'hAA;
    #10;
    
    wr_address_tb=3'b001;
    data_in_tb=8'h4B;
    #10;
    
    wr_address_tb=3'b010;
    data_in_tb=8'h78;
    #10;
    
    wr_address_tb=3'b011;
    data_in_tb=8'h41;
    #10;
    
   
    //reading data
    wrenb_tb=0;
    rd_address_tb=3'b000;
    #10;
    
    rd_address_tb=3'b001;
    #10;
    
    rd_address_tb=3'b010;
    #10;
    
    rd_address_tb=3'b011;
    #10;
    
    //asynchronous reset
    #5;
    arstn_tb=0;
    #10;
    
    $finish;
    
    
    end
    
endmodule
