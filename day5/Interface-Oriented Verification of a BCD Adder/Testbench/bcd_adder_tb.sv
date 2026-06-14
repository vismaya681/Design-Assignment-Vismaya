
interface bcd_adder_if;
    logic [3:0] A;
    logic [3:0] B;
    logic       Cin;
    logic [3:0] S;
    logic       Cout;
endinterface




module bcd_adder_tb();



    // 1. Instantiate Interface
    bcd_adder_if bcd_if();


    logic [3:0] A_tb;
    logic [3:0] B_tb;
    logic       Cin_tb;
    logic [3:0] S_tb;
    logic       Cout_tb;

    
    assign bcd_if.A   = A_tb;
    assign bcd_if.B   = B_tb;
    assign bcd_if.Cin = Cin_tb;
    assign S_tb    = bcd_if.S;
    assign Cout_tb = bcd_if.Cout;

    bcd_adder dut (
        bcd_if.A,
        bcd_if.B,
        bcd_if.Cin,
        bcd_if.S,
        bcd_if.Cout
    );

    
    initial begin
        A_tb   = 4'd4;
        B_tb   = 4'd4;
        Cin_tb = 1'b0;
        #10;
        
        A_tb   = 4'd5;
        B_tb    = 4'd5;
        Cin_tb  = 1'b0;
        #10;

        A_tb   = 4'd9;
        B_tb   = 4'd9;
        Cin_tb = 1'b1;
        #10;
    end

    initial begin
        $monitor("Time=%0t ns | A=%0d, B=%0d, Cin=%b -> Cout=%b, S=%0d", 
                 $time, A_tb, B_tb, Cin_tb, Cout_tb, S_tb);
        #35; 
        $finish();
    end

endmodule

