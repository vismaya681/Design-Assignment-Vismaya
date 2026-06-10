module seq_det1110(input clk,rst,din, output reg detected

    );
    parameter idle=2'b00;
    parameter s1=2'b01;
    parameter s2=2'b10;
    parameter s3=2'b11;
    reg [1:0] ps,ns;
    //present state logic
    always @(posedge clk)
    begin
    if (rst) begin
    ps<=idle;
    end
    else 
    ps<=ns;
    end 
    
    //next state logic
    always @(*)
    begin
    case (ps)
    idle: begin
    detected=0;
    if (din==0)
    ns=idle;
    else
    ns=s1;
    end
    
    
    s1: begin
    detected=0;
    if (din==0)
    ns=idle;
    else
    ns=s2;
    end
    
    s2: begin
    detected=0;
    if (din==0)
    ns=idle;
    else
    ns=s3;
    end
    
    s3: begin
    if (din==0) begin
    ns=idle;
    detected=1;
    end
    else begin
    ns=s3;
    detected=0;
    end
    end
    
    
    default: begin
    ns=idle;
    detected=1'b0;
    end
    endcase
    end
    
    
    
endmodule
