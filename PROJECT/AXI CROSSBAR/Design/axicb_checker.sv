`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 12:41:04
// Design Name: 
// Module Name: axicb_checker
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


`ifndef AXICB_CHECKERS
`define AXICB_CHECKERS

`define CHECKER(condition, msg)\
    if (condition) begin \
        $display("\033[1;31mERROR: %s\033[0m", msg); \
        $finish(1); \
    end

`endif
