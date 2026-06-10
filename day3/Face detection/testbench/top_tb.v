module top_tb;

reg clk_tb;
reg rst_tb;
reg [7:0] sin_tb;
wire [7:0] dout_tb;

top dut(
    .clk(clk_tb),
    .rst(rst_tb),
    .sin(sin_tb),
    .dout(dout_tb)
);

initial
begin
    clk_tb = 0;
    rst_tb = 1;
    sin_tb = 8'h00;

    #10 rst_tb = 0;
end

always #5 clk_tb = ~clk_tb;

initial
begin
    #15 sin_tb = 8'h4f;
    #10 sin_tb = 8'h2c;
    #10 sin_tb = 8'h13;
    #10 sin_tb = 8'h46;
    #10 sin_tb = 8'h59;
    #10 sin_tb = 8'h21;
    #10 sin_tb = 8'h19;
    #10 sin_tb = 8'haa;

    #200;
    $finish;
end

endmodule
