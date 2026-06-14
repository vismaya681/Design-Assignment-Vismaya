interface fifo_if;
    logic       clk;
    logic       rst;
    logic       wr_enb;
    logic       rd_enb;
    logic [7:0] data_in;
    logic       full;
    logic       empty;
    logic [7:0] data_out;
endinterface

`timescale 1ns / 1ps

module fifo_tb();

    // Instantiate Interface
    fifo_if fif();

  
    logic       clk_tb;
    logic       rst_tb;
    logic       wr_enb_tb;
    logic       rd_enb_tb;
    logic [7:0] data_in_tb;
    logic       full_tb;
    logic       empty_tb;
    logic [7:0] data_out_tb;

    // Continuous assignment mapping between tracking signals and interface
    assign fif.clk      = clk_tb;
    assign fif.rst      = rst_tb;
    assign fif.wr_enb   = wr_enb_tb;
    assign fif.rd_enb   = rd_enb_tb;
    assign fif.data_in  = data_in_tb;
    assign full_tb      = fif.full;
    assign empty_tb     = fif.empty;
    assign data_out_tb  = fif.data_out;

    //  Connect Design Under Test (DUT) via interface connections
    fifo_des dut (
        fif.clk,
        fif.rst,
        fif.wr_enb,
        fif.rd_enb,
        fif.data_in,
        fif.full,
        fif.empty,
        fif.data_out
    );

    //  Independent Clock Generation
    initial begin
        clk_tb = 0;
        forever #5 clk_tb = ~clk_tb; // 10ns clock period
    end

    
    initial begin
        // Reset state initialization
        rst_tb     = 1;
        wr_enb_tb  = 0;
        rd_enb_tb  = 0;
        data_in_tb = 8'h00;
        #15; // Hold reset through the first rising edge
        
        // Release reset
        rst_tb     = 0;
        #10;

        // Write operation 1: Write 8'hAA
        wr_enb_tb  = 1;
        data_in_tb = 8'hAA;
        #10;

        // Write operation 2: Write 8'hBB
        data_in_tb = 8'hBB;
        #10;

        // Stop writing, wait a bit
        wr_enb_tb  = 0;
        #10;

        // Read operation 1
        rd_enb_tb  = 1;
        #10;

        // Read operation 2
        #10;

        // Stop reading
        rd_enb_tb  = 0;
    end

  
    initial begin
        $monitor("Time=%0t ns | rst=%b | wr=%b, din=0x%h | rd=%b, dout=0x%h | full=%b, empty=%b", 
                 $time, rst_tb, wr_enb_tb, data_in_tb, rd_enb_tb, data_out_tb, full_tb, empty_tb);
        
        
        #90; 
        $finish();
    end

endmodule


