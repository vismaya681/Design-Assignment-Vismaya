module bcd_adder(
    input [3:0] A,
    input [3:0] B,
    input Cin,
    output [3:0] S,
    output Cout
);

    wire [3:0] S1;
    wire Cout1;
    wire adjust;
    wire [3:0] B2;
    wire dummy_cout;

    rca RCA1 (
        .A(A),
        .B(B),
        .Cin(Cin),
        .S(S1),
        .Cout(Cout1)
    );

    assign adjust = Cout1 | (S1[3] & S1[2]) | (S1[3] & S1[1]);
    assign B2 = {1'b0, adjust, adjust, 1'b0};
    assign Cout = adjust;

    rca RCA2 (
        .A(S1),
        .B(B2),
        .Cin(1'b0),
        .S(S),
        .Cout(dummy_cout)
    );


endmodule

