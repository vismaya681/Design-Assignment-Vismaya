module face(
input clk,
    input [7:0] sin,
    output reg [7:0] sout
    );

always @(posedge clk)
begin
    sout <= sin;
end

endmodule

