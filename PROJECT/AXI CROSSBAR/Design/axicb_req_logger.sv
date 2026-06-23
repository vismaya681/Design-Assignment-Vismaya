`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 13:28:04
// Design Name: 
// Module Name: axicb_req_logger
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


//------------------------------------------------------------------------------
// AXI Crossbar Request Logger (Fixed)
//------------------------------------------------------------------------------

module axicb_req_logger #(
    parameter integer MASTERS      = 4,
    parameter integer COUNTER_W    = 32
)(
    input  wire                              aclk,
    input  wire                              aresetn,
    input  wire                              window_clear, // Added to reset metrics periodically

    // Write address channel handshake observation
    input  wire [MASTERS-1:0]                awvalid,
    input  wire [MASTERS-1:0]                awready,

    // Read address channel handshake observation
    input  wire [MASTERS-1:0]                arvalid,
    input  wire [MASTERS-1:0]                arready,

    // Request counts exported to arbiter
    output logic [COUNTER_W-1:0]             req_count [0:MASTERS-1]
);

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            for (int i = 0; i < MASTERS; i++) begin
                req_count[i] <= '0;
            end
        end
        else begin
            for (int i = 0; i < MASTERS; i++) begin
                // 1. Calculate the increment step for this cycle
                automatic logic aw_hs = awvalid[i] && awready[i];
                automatic logic ar_hs = arvalid[i] && arready[i];
                automatic logic [1:0] inc = aw_hs + ar_hs; // Can be 2'b00, 2'b01, or 2'b10

                // 2. Apply tracking logic with window reset capability
                if (window_clear) begin
                    req_count[i] <= inc; // Start the new window with current cycle's data
                end
                else begin
                    req_count[i] <= req_count[i] + inc;
                end
            end
        end
    end

endmodule
