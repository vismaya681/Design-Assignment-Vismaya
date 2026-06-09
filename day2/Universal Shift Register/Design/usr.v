module usr(input clk,rst,sin,input [3:0] pin,input [1:0] mod,input load, output reg sout,output reg [3:0] pout);

reg [3:0] temp;

always @(posedge clk) begin
    if (rst) begin
        temp <= 4'b0000;
        pout <= 4'b0000;
        sout <= 1'b0;
    end
    else begin
        case (mod)

            2'b00: begin
                temp <= temp >> 1'b1;
                temp[3] <= sin;
                sout <= temp[0];
                pout <= temp;
            end

            2'b01: begin
                temp <= temp >> 1'b1;
                temp[3] <= sin;
                pout <= temp;
            end

            2'b10: begin
                if (load == 1'b1)
                    temp <= pin;
                else begin
                    temp <= temp >> 1'b1;
                    temp[3] <= sin;
                    sout <= temp[0];
                end
                pout <= temp;
            end

            2'b11: begin
                if (load == 1'b1)
                    temp <= pin;

                pout <= temp;
                sout <= temp[0];
            end

            default: begin
                temp <= 4'b0000;
                pout <= 4'b0000;
                sout <= 1'b0;
             end

        endcase
    end
end

endmodule
