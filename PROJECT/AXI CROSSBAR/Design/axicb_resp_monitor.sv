`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 13:03:58
// Design Name: 
// Module Name: axicb_resp_monitor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2026 21:53:27
// Design Name: 
// Module Name: axicb_resp_monitor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`default_nettype none

module axicb_resp_monitor
#(
    parameter COUNTER_W = 32
)
(
    input  wire                 aclk,
    input  wire                 aresetn,
    input wire                  srst,

    //--------------------------------------------------
    // B Channel
    //--------------------------------------------------
    input  wire                 bvalid,
    input  wire                 bready,
    input  wire [1:0]           bresp,

    //--------------------------------------------------
    // R Channel
    //--------------------------------------------------
    input  wire                 rvalid,
    input  wire                 rready,
    input  wire [1:0]           rresp,

    //--------------------------------------------------
    // Status
    //--------------------------------------------------
    output logic                b_error_flag,
    output logic                r_error_flag,

    output logic [COUNTER_W-1:0] b_error_count,
    output logic [COUNTER_W-1:0] r_error_count
);

localparam AXI_RESP_SLVERR = 2'b10;
localparam AXI_RESP_DECERR = 2'b11;

wire b_error;
wire r_error;

assign b_error =
       bvalid && bready &&
      ((bresp == AXI_RESP_SLVERR) ||
       (bresp == AXI_RESP_DECERR));

assign r_error =
       rvalid && rready &&
      ((rresp == AXI_RESP_SLVERR) ||
       (rresp == AXI_RESP_DECERR));

always_ff @(posedge aclk or negedge aresetn)
begin
    if(!aresetn)
    begin
        b_error_count <= '0;
        r_error_count <= '0;

        b_error_flag  <= 1'b0;
        r_error_flag  <= 1'b0;
    end
    
    else if(srst) begin
        b_error_count <= '0;
        r_error_count <= '0;

        b_error_flag  <= 1'b0;
        r_error_flag  <= 1'b0;
    end
    
    else
    begin

        if(b_error)
        begin
            if(b_error_count != {COUNTER_W{1'b1}}) begin
                b_error_count <= b_error_count + 1'b1;
                b_error_flag  <= 1'b1;
        end
        end

        if(r_error)
        begin
            if(r_error_count != {COUNTER_W{1'b1}}) begin
            r_error_count <= r_error_count + 1'b1;
            r_error_flag  <= 1'b1;
        end
        end
    end
end

endmodule

`default_nettype wire
