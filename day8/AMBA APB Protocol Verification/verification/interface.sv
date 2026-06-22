interface apb_if(input logic pclk, input logic presetn);
    logic [31:0] paddr;
    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [31:0] pwdata;
    logic        pready;
    logic        pslverr;
    logic [31:0] prdata;
endinterface
