module fulladd_behav(input a,b,cin,output  reg sum,cout

    );
    always @(*)
    begin
    sum = a^b^cin;
    cout = (a & b)|(b & cin)|(a & cin);
    end
endmodule
