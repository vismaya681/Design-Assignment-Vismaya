

module out(
    input clk,
    input rst,
    output reg rd_enb
);

parameter S0 = 2'b00;
parameter S1 = 2'b01;
parameter S2 = 2'b10;

reg [1:0] state;

always @(posedge clk)
begin
    if(rst)
    begin
        state <= S0;
        rd_enb <= 1'b0;
    end
    else
    begin
        case(state)

        S0:
        begin
            rd_enb <= 1'b0;
            state <= S1;
        end

        S1:
        begin
            rd_enb <= 1'b0;
            state <= S2;
        end

        S2:
        begin
            rd_enb <= 1'b1;
            state <= S0;
        end

        default:
        begin
            rd_enb <= 1'b0;
            state <= S0;
        end

        endcase
    end
end

endmodule
