module block_ram(input clk,arstn,wrenb,input [7:0]wr_address,input [7:0]rd_address,input [7:0]data_in,output reg [7:0]data_out

    );
    reg [7:0] memory[7:0];
    integer i;
    always @(posedge clk or negedge arstn) begin
        if (!arstn) begin
            // Asynchronous active-low reset
            for (i=0;i<8;i=i+1)
            memory[i]<=8'b0;
            data_out <= 8'b0;
        end 
        else begin
            if (wrenb == 1'b1) begin
                // Write Operation
                memory[wr_address] <= data_in;
            end else begin
                // Read Operation (wrenb == 0)
                data_out <= memory[rd_address];
            end
        end
    end
endmodule

