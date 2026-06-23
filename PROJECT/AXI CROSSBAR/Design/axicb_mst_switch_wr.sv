`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.06.2026 19:59:52
// Design Name: 
// Module Name: axicb_mst_switch_wr
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


// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module axicb_mst_switch_wr

    #(
        // ID width in bits
        parameter AXI_ID_W = 8,
        // Data width in bits
        parameter AXI_DATA_W = 8,

        // Number of master(s)
        parameter MST_NB = 4,

        // Maximum number of priority in Round-Robin for Masters selections
        parameter NUM_PRIORITY_LVL = 4,

        // Activate the timer to avoid deadlock
        parameter TIMEOUT_ENABLE = 1,
        // Timeout value in clock cycles
        parameter TIMEOUT_VAL = 256,

        // Masters ID mask
        parameter [AXI_ID_W*MST_NB-1:0] MST_ID_MASK = 'h30_20_10_00,

        // Masters priorities
        parameter PRIORITY_W = 2,
        parameter [PRIORITY_W*MST_NB-1:0] MST_PRIORITY = 0,

        // Channels' width (concatenated)
        parameter AWCH_W = 8,
        parameter WCH_W = 8,
        parameter BCH_W = 8,
        parameter ARCH_W = 8,
        parameter RCH_W = 8
    )(
        // Global interface
        input  wire                           aclk,
        input  wire                           aresetn,
        input  wire                           srst,
        // Input interfaces from masters
        
        input  wire  [MST_NB            -1:0] i_awvalid,
        output logic [MST_NB            -1:0] i_awready,
        input  wire  [MST_NB*AWCH_W     -1:0] i_awch,
        input  wire  [MST_NB            -1:0] i_wvalid,
        output logic [MST_NB            -1:0] i_wready,
        input  wire  [MST_NB            -1:0] i_wlast,
        input  wire  [MST_NB*WCH_W      -1:0] i_wch,
        output logic [MST_NB            -1:0] i_bvalid,
        input  wire  [MST_NB            -1:0] i_bready,
        output logic [BCH_W             -1:0] i_bch,
        // Output interfaces to slaves
        output logic                          o_awvalid,
        input  wire                           o_awready,
        output logic [AWCH_W            -1:0] o_awch,
        output logic                          o_wvalid,
        input  wire                           o_wready,
        output logic                          o_wlast,
        output logic [WCH_W             -1:0] o_wch,
        input  wire                           o_bvalid,
        output logic                          o_bready,
        input  wire  [BCH_W             -1:0] o_bch
    );


    ///////////////////////////////////////////////////////////////////////////
    // Local declarations
    ///////////////////////////////////////////////////////////////////////////

    logic                  awch_en;
    logic                  awch_en_c;
    logic                  awch_en_r;
    logic [MST_NB    -1:0] awch_req;
    logic [MST_NB    -1:0] awch_grant;

    logic [MST_NB    -1:0] wch_grant;

    logic [MST_NB    -1:0] mst_bch_targeted;
    logic                  write_service_done;
    logic [MST_NB-1:0]     write_completed_master;
    
    logic                  fairness_mode_wr;
    logic [MST_NB-1:0]     blocked_master_wr;
    logic [MST_NB-1:0]     served_mask_wr;

    logic                  wch_full;
    logic                  wch_empty;

    // Timeout logic internal registers
    logic [7:0]                           outstanding_tx_cnt; 
    logic [$clog2(TIMEOUT_VAL+1)-1:0]    timeout_timer;
    logic                                 timeout_triggered;


    ///////////////////////////////////////////////////////////////////////////
    // Write Address Channel
    ///////////////////////////////////////////////////////////////////////////

    assign awch_req = i_awvalid;

    axicb_fairness_arbiter
#(
    .MST_NB           (MST_NB),
    .PRIORITY_W       (PRIORITY_W),
    .NUM_PRIORITY_LVL (NUM_PRIORITY_LVL),
    .MST_PRIORITY     (MST_PRIORITY),
    .DOMINANCE_LIMIT  (5)
)
awch_fairness
(
    .aclk              (aclk),
    .aresetn           (aresetn),
    .srst              (srst),

    .req               (awch_req),

    .service_done      (write_service_done),

    .completed_master  (write_completed_master),

    .grant             (awch_grant),

    .fairness_mode     (fairness_mode_wr),
    .blocked_master    (blocked_master_wr),
    .served_mask       (served_mask_wr)
);
    always_comb begin

        o_awvalid = '0;

        for (int i=0; i<MST_NB; i++)
            if (awch_grant[i])
                o_awvalid = i_awvalid[i];
    end

    assign i_awready = awch_grant & {MST_NB{o_awready & !wch_full}};

    assign awch_en_c = |i_awvalid & o_awready;

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awch_en_r <= '0; end
         else if (srst) begin
            awch_en_r <= '0; end
         else begin
            if (awch_grant=='0) awch_en_r <= 1'b1;
            else                awch_en_r <= 1'b0;
        end
    end

    assign awch_en = awch_en_c | awch_en_r;

    always_comb begin

        o_awch = '0;

        if (awch_grant == '0)
            o_awch = '0;
        else
            for (int i=0;i<MST_NB;i++)
                if (awch_grant[i])
                    o_awch = i_awch[i*AWCH_W+:AWCH_W];
    end



    ///////////////////////////////////////////////////////////////////////////
    // Write Data Channel
    ///////////////////////////////////////////////////////////////////////////

    axicb_scfifo
    #(
    .PASS_THRU  (0),
    .ADDR_WIDTH (8),
    .DATA_WIDTH (MST_NB)
    )
    wch_gnt_fifo
    (
    .aclk     (aclk),
    .aresetn  (aresetn),
    .srst     (srst),
    .flush    (1'b0),
    .data_in  (awch_grant),
    .push     (o_awvalid & o_awready),
    .full     (wch_full),
    .data_out (wch_grant),
    .pull     (o_wvalid & o_wready & o_wlast),
    .empty    (wch_empty)
    );

    assign i_wready = (wch_empty) ? {MST_NB{1'b0}} :
                                    wch_grant & {MST_NB{o_wready}};

    always_comb begin

        o_wvalid = '0;
        o_wlast = '0;
        o_wch = '0;

        if (wch_empty) begin
            o_wvalid = '0;
            o_wlast = '0;
            o_wch = '0;
        end else if (wch_grant == '0) begin
            o_wvalid = '0;
            o_wlast = '0;
            o_wch = '0;
        end else begin
            for (int i=0;i<MST_NB;i++) begin
                if (wch_grant[i]) begin
                    o_wvalid = i_wvalid[i];
                    o_wlast = i_wlast[i];
                    o_wch = i_wch[i*WCH_W+:WCH_W];
                end
            end
        end 
    end


    ///////////////////////////////////////////////////////////////////////////
    // Write Response channel
    ///////////////////////////////////////////////////////////////////////////

    // BCH = {RESP, ID}

    generate
    genvar i;
        for (i = 0; i < MST_NB; i = i + 1) begin : MST_BCH_TARGET
            assign mst_bch_targeted[i] = ((MST_ID_MASK[i*AXI_ID_W+:AXI_ID_W] & o_bch[0+:AXI_ID_W]) == MST_ID_MASK[i*AXI_ID_W+:AXI_ID_W]);
        end
    endgenerate

    assign write_service_done =
       o_bvalid &&
       o_bready;

assign write_completed_master =
       mst_bch_targeted &
       {MST_NB{write_service_done}};
    always_comb begin
        o_bready = '0;
        if (timeout_triggered) begin
            o_bready = '0;
        end else if (mst_bch_targeted == '0) begin
            o_bready = '0;
        end else begin
            for (int i=0; i<MST_NB; i++) begin
                if (mst_bch_targeted[i])
                    o_bready = i_bready[i];
            end
        end
    end


    ///////////////////////////////////////////////////////////////////////////
    // Timeout Mechanism Implementation
    ///////////////////////////////////////////////////////////////////////////
    logic master_bready_any;
    assign master_bready_any = |(mst_bch_targeted & i_bready);

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            outstanding_tx_cnt <= '0;
            timeout_timer      <= '0;
            timeout_triggered  <= 1'b0;
        end else if (srst) begin
            outstanding_tx_cnt <= '0;
            timeout_timer      <= '0;
            timeout_triggered  <= 1'b0;
        end else if (TIMEOUT_ENABLE) begin
            // Track outstanding requests through address handshakes
            if ((o_awvalid && o_awready) && !o_bvalid) begin
                outstanding_tx_cnt <= outstanding_tx_cnt + 1'b1;
            end else if (!(o_awvalid && o_awready) && (o_bvalid && o_bready)) begin
                outstanding_tx_cnt <= outstanding_tx_cnt - 1'b1;
            end

            // Monitor downstream inactivity
            if (outstanding_tx_cnt > 0 && !timeout_triggered) begin
                if (timeout_timer >= TIMEOUT_VAL - 1) begin
                    timeout_triggered <= 1'b1;
                end else if (o_bvalid) begin
                    timeout_timer <= '0; // Reset watchdog when downstream progress occurs
                end else begin
                    timeout_timer <= timeout_timer + 1'b1;
                end
            end else if (timeout_triggered) begin
                if (master_bready_any) begin
                    timeout_triggered <= 1'b0;
                    timeout_timer      <= '0;
                end
            end else begin
                timeout_timer <= '0;
            end
        end
    end

    always_comb begin
        if (TIMEOUT_ENABLE && timeout_triggered) begin
            i_bch = {2'h3, o_bch[0+:AXI_ID_W]}; // Inject DECERR (2'h3) payload
            for (int i = 0; i < MST_NB; i++) begin
                i_bvalid[i] = mst_bch_targeted[i];
            end
        end else begin
            i_bch = o_bch;
            for (int i = 0; i < MST_NB; i++) begin
                i_bvalid[i] = (mst_bch_targeted[i]) ? o_bvalid : 1'b0;
            end
        end
    end

endmodule

`resetall
