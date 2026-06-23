`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.06.2026 21:04:46
// Design Name: 
// Module Name: axicb_fairness_arbiter
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


module axicb_fairness_arbiter
#(
parameter MST_NB           = 4,
parameter PRIORITY_W       = 2,
parameter NUM_PRIORITY_LVL = 4,
parameter DOMINANCE_LIMIT  = 5,


parameter [PRIORITY_W*MST_NB-1:0]
          MST_PRIORITY = 0


)
(
input  wire                     aclk,
input  wire                     aresetn,
input  wire                     srst,


input  wire [MST_NB-1:0]        req,

input  wire                     service_done,

input  wire [MST_NB-1:0]        completed_master,

output wire [MST_NB-1:0]        grant,

output logic                    fairness_mode,
output logic [MST_NB-1:0]       blocked_master,
output logic [MST_NB-1:0]       served_mask


);

localparam IDLE     = 1'b0;
localparam FAIRNESS = 1'b1;

logic state;

logic [$clog2(DOMINANCE_LIMIT+1)-1:0] dominance_cnt;

logic [MST_NB-1:0] requester_mask;
logic [MST_NB-1:0] arb_req;

logic [MST_NB-1:0] dominant_master;
logic [MST_NB-1:0] next_served_mask;

//////////////////////////////////////////////////////
// Request filtering
//////////////////////////////////////////////////////

always_comb begin
arb_req = req;


if (state == FAIRNESS)
    arb_req = req & ~blocked_master;


end

//////////////////////////////////////////////////////
// Existing AXICB RR + Priority Arbiter
//////////////////////////////////////////////////////

axicb_round_robin
#(
.REQ_NB           (MST_NB),
.PRIORITY_W       (PRIORITY_W),
.NUM_PRIORITY_LVL (NUM_PRIORITY_LVL),
.PRIORITY         (MST_PRIORITY)
)
u_rr
(
.aclk     (aclk),
.aresetn  (aresetn),
.srst     (srst),
.en       (1'b1),
.req      (arb_req),
.grant    (grant)
);

//////////////////////////////////////////////////////
// Helper
//////////////////////////////////////////////////////

always_comb begin
next_served_mask = served_mask;


if (service_done)
    next_served_mask = served_mask | completed_master;


end

//////////////////////////////////////////////////////
// Dominance Counter
//////////////////////////////////////////////////////

always_ff @(posedge aclk or negedge aresetn)
begin
if (!aresetn) begin
dominance_cnt   <= '0;
dominant_master <= '0;
end
else if (srst) begin
dominance_cnt   <= '0;
dominant_master <= '0;
end
else begin


    if (req == '0) begin
        dominance_cnt   <= '0;
        dominant_master <= '0;
    end
    else if (state == FAIRNESS) begin
        dominance_cnt <= '0;
    end
    else if (service_done) begin

        dominant_master <= completed_master;

        if (|(req & ~completed_master))
            dominance_cnt <= dominance_cnt + 1'b1;
        else
            dominance_cnt <= '0;
    end

end


end

//////////////////////////////////////////////////////
// Fairness FSM
//////////////////////////////////////////////////////

always_ff @(posedge aclk or negedge aresetn)
begin
if (!aresetn) begin


    state          <= IDLE;
    blocked_master <= '0;
    requester_mask <= '0;
    served_mask    <= '0;

end
else if (srst) begin

    state          <= IDLE;
    blocked_master <= '0;
    requester_mask <= '0;
    served_mask    <= '0;

end
else begin

    case(state)

    //////////////////////////////////////////////
    // NORMAL MODE
    //////////////////////////////////////////////

    IDLE:
    begin

        served_mask <= '0;

        if (dominance_cnt >= DOMINANCE_LIMIT) begin

            state <= FAIRNESS;

            blocked_master <= dominant_master;

            requester_mask <= req & ~dominant_master;

            served_mask <= '0;

        end

        if (req == '0) begin

            blocked_master <= '0;
            requester_mask <= '0;
            served_mask    <= '0;

        end
    end

    //////////////////////////////////////////////
    // FAIRNESS MODE
    //////////////////////////////////////////////

    FAIRNESS:
    begin

        if (service_done)
            served_mask <= served_mask | completed_master;

        if (next_served_mask == requester_mask) begin

            state <= IDLE;

            blocked_master <= '0;
            requester_mask <= '0;
            served_mask    <= '0;

        end

        if (req == '0) begin

            state <= IDLE;

            blocked_master <= '0;
            requester_mask <= '0;
            served_mask    <= '0;

        end
    end

    endcase
end


end

//////////////////////////////////////////////////////
// Status
//////////////////////////////////////////////////////

always_comb begin
fairness_mode = (state == FAIRNESS);
end

endmodule
