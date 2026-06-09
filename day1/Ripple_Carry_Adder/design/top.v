module rca(input [3:0]A,[3:0]B,Cin, output [3:0]S,output Cout

    );
    wire c1,c2,c3;
    fulladd_behav FA1(A[0],B[0],Cin,S[0],c1);
    fulladd_behav FA2(A[1],B[1],c1,S[1],c2);
    fulladd_behav FA3(A[2],B[2],c2,S[2],c3);
    fulladd_behav FA4(A[3],B[3],c3,S[3],Cout);
    
endmodule

