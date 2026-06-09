module bcd_tb();

    reg [3:0] A;
    reg [3:0] B;
    reg Cin;

    wire [3:0] S;
    wire Cout;

    bcd uut (
        .A(A), 
        .B(B), 
        .Cin(Cin), 
        .S(S), 
        .Cout(Cout)
    );

    initial begin
        A = 4'b0000;
        B = 4'b0000;
        Cin = 1'b0;
        #100;
        
        A = 4'd3; B = 4'd5; Cin = 1'b0;
        #20;
        
        A = 4'd4; B = 4'd2; Cin = 1'b1;
        #20;

        A = 4'd6; B = 4'd4; Cin = 1'b0;
        #20;

        A = 4'd8; B = 4'd7; Cin = 1'b0;
        #20;

        A = 4'd9; B = 4'd9; Cin = 1'b1;
        #20;
        
        A = 4'd0; B = 4'd0; Cin = 1'b0;
        #20;

        $finish;
    end

endmodule
