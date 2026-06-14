module fifo_des(

    input clk,
    input rst,
    input wr_enb,
    input rd_enb,
    input [7:0] data_in,
    output reg full,
    output reg empty,
    output reg [7:0] data_out
);

reg [7:0] mem[7:0];
reg [2:0] wr_ptr;
reg [2:0] rd_ptr;

integer i;

always @(posedge clk)
begin
    if(rst)
    begin
        wr_ptr <= 3'b000;
        rd_ptr <= 3'b000;
        full <= 1'b0;
        empty <= 1'b1;
        data_out <= 8'h00;

        for(i=0;i<8;i=i+1)
            mem[i] <= 8'h00;
    end
    else
    begin
        if(wr_enb && !full)
        begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1'b1;
        end

        if(rd_enb && !empty)
        begin
            data_out <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1'b1;
        end

        if((wr_ptr + 1'b1) == rd_ptr)
            full <= 1'b1;
        else
            full <= 1'b0;

        if(wr_ptr == rd_ptr)
            empty <= 1'b1;
        else
            empty <= 1'b0;
    end
end
endmodule
