class fifo_transaction;
    rand bit wr_en,rd_en;
    rand bit [7:0] data_in;
    bit [7:0] data_out;
    bit full,empty;
    constraint wr_rd_c {(wr_en != rd_en);}
    
    function void display(string s);
        $display("[%s] wr_en=%0b rd_en=%0b data_in=%0b data_out=%0b full=%0b empty=%0b",
                 s, wr_en, rd_en, data_in, data_out, full, empty);
    endfunction
endclass

module fifo;
        fifo_transaction tr;
        initial begin 
        tr=new();
        repeat (10) begin
            if (tr.randomize()) 
                tr.display("TRANSACTION");     
            else 
                $display("Randomization Failed");
            #10;
        end
        $finish;    
  end      
endmodule
