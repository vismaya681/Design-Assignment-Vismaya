module usr_tb;

reg clk_tb, rst_tb, sin_tb, load_tb;
reg [3:0] pin_tb;
reg [1:0] mod_tb;
wire sout_tb;
wire [3:0] pout_tb;
usr dut( clk_tb,rst_tb,sin_tb,pin_tb,mod_tb,load_tb,sout_tb,pout_tb);
initial begin
clk_tb = 0;
end
always #5 clk_tb = ~clk_tb;
initial begin
rst_tb = 1;
sin_tb = 0;
pin_tb = 0;
load_tb = 0;
mod_tb = 2'b00;
#10;
rst_tb = 0;
mod_tb = 2'b00;
sin_tb = 1; #10;
sin_tb = 0; #10;
sin_tb = 1; #10;
sin_tb = 1; #10;
mod_tb = 2'b01;
sin_tb = 1; #10;
sin_tb = 0; #10;
sin_tb = 1; #10;
sin_tb = 0; #10;
mod_tb = 2'b10;
load_tb = 1;
pin_tb = 4'b1101;
#10;
load_tb = 0;
sin_tb = 1; #10;
sin_tb = 0; #10;
sin_tb = 1; #10;
mod_tb = 2'b11;
load_tb = 1;
pin_tb = 4'b1010;
#10;
load_tb = 0;
#20;
end
endmodule

