module encoder4by2(input [3:0]D,output reg[1:0]b

    );
    always @(*)
    begin
    case(D)
    4'b0001:b=2'b00;
    4'b0010:b=2'b01;
    4'b0100:b=2'b10;
    4'b1000:b=2'b11;
    endcase 
    end
endmodule

