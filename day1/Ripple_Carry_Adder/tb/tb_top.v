module rca_tb(

    );
    reg [3:0]A_tb;
    reg [3:0]B_tb;
    reg Cin_tb;
    
    wire [3:0]S_tb;
    wire Cout_tb;

    
    rca dut(A_tb, B_tb, Cin_tb, S_tb, Cout_tb);
    
    initial
    begin
    {A_tb, B_tb, Cin_tb} = 0;
    end
    
    initial
    begin
    A_tb = 4'b0000;
    B_tb = 4'b0000;
    Cin_tb = 1'b0;
    #1;
    
    A_tb = 4'b0010;
    B_tb = 4'b0011;
    Cin_tb = 1'b0;
    #1;
    
    A_tb = 4'b0101;
    B_tb = 4'b0010;
    Cin_tb = 1'b1;
    #1;
    
    
    A_tb = 4'b1111;
    B_tb = 4'b0000;
    Cin_tb = 1'b0;
    #1;
    
    
    A_tb = 4'b1111;
    B_tb = 4'b1111;
    Cin_tb = 1'b1;
    #1;
    
    $monitor("the value of A_tb is %b the value of B_tb is %b the value of Cin_tb is %b the value of S_tb is %b the value of Cout_tb is %b ", A_tb, B_tb, Cin_tb, S_tb, Cout_tb);
    end
endmodule

