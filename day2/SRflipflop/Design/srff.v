module srff(input s,r,rst,clk, output reg q,qbar

    );
    always @(posedge clk) begin
        if (rst) begin
            q<=1'b0;
            qbar<=1'b1; 
        end
        else begin
            case({s,r})
                2'b00: begin
                q<=q;
                qbar<=qbar;
                end 
                2'b01: begin
                q<=1'b0;
                qbar<=1'b1;
                end 
                2'b10: begin
                q<=1'b1;
                qbar<=1'b0;
                end 
                2'b11: begin
                q<='bx;
                qbar<='bx;
                end 
                
            endcase
        end
    end
endmodule
