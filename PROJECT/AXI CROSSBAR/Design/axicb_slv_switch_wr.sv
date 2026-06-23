`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 13:30:38
// Design Name: 
// Module Name: axicb_slv_switch_wr
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

module axicb_slv_switch_wr

    #(
        // Address width in bits
        parameter AXI_ADDR_W = 8,
        // ID width in bits
        parameter AXI_ID_W = 8,

        // AXI Signals Supported:
        //   - 0: AXI4-lite
        //   - 1: AXI4
        parameter AXI_SIGNALING = 0,

        // Number of slave(s)
        parameter SLV_NB = 4,

        // Activate the timer to avoid deadlock
        parameter TIMEOUT_ENABLE = 1,
        // Timeout value in clock cycles
        parameter TIMEOUT_VAL = 256,

        // Routes allowed to use by this master
        parameter MST_ROUTES = 4'b1_1_1_1,

        // Max Outstanding Request
        parameter MST_OSTDREQ_NUM = 4,

        // Master ID mask
        parameter [AXI_ID_W-1:0] MST_ID_MASK = 'h00,

        // Slave Memory Mapping
        parameter [AXI_ADDR_W * SLV_NB - 1:0] SLV_START_ADDR = '0,
        parameter [AXI_ADDR_W * SLV_NB - 1:0] SLV_END_ADDR = '0,

        // Channels' width (concatenated)
        parameter AWCH_W = 8,
        parameter WCH_W = 8,
        parameter BCH_W = 10,
        parameter ARCH_W = 8,
        parameter RCH_W = 8
    )(
        // Global interface
        input  wire                           aclk,
        input  wire                           aresetn,
        input  wire                           srst,
        // Input interface from master
        input  wire                           i_awvalid,
        output logic                          i_awready,
        input  wire  [AWCH_W            -1:0] i_awch,
        input  wire                           i_wvalid,
        output logic                          i_wready,
        input  wire                           i_wlast,
        input  wire  [WCH_W             -1:0] i_wch,
        output logic                          i_bvalid,
        input  wire                           i_bready,
        output logic [BCH_W             -1:0] i_bch,
        // Output interfaces to slaves
        output logic [SLV_NB            -1:0] o_awvalid,
        input  wire  [SLV_NB            -1:0] o_awready,
        output logic [AWCH_W            -1:0] o_awch,
        output logic [SLV_NB            -1:0] o_wvalid,
        input  wire  [SLV_NB            -1:0] o_wready,
        output logic [SLV_NB            -1:0] o_wlast,
        output logic [WCH_W             -1:0] o_wch,
        input  wire  [SLV_NB            -1:0] o_bvalid,
        output logic [SLV_NB            -1:0] o_bready,
        input  wire  [SLV_NB*BCH_W      -1:0] o_bch
    );


    ///////////////////////////////////////////////////////////////////////////
    // Local declarations
    ///////////////////////////////////////////////////////////////////////////

    logic [SLV_NB    -1:0] slv_aw_targeted;
    logic [SLV_NB    -1:0] slv_w_targeted;
    logic                  aw_misrouting;
    logic                  aw_misrouting_c;

    logic                  wch_full;
    logic                  bch_full;
    logic                  wch_empty;

    logic [AXI_ID_W  -1:0] a_id;
    logic                  a_mr;

    logic                  bch_en;
    logic                  bch_en_c;
    logic                  bch_en_r;
    logic [SLV_NB    -1:0] bch_grant;
    logic                  bch_mr;
    logic [AXI_ID_W  -1:0] bch_id;
    logic                  c_end;

    // Timeout logic internal registers
    logic [$clog2(MST_OSTDREQ_NUM+1)-1:0] outstanding_tx_cnt;
    logic [$clog2(TIMEOUT_VAL+1)-1:0]    timeout_timer;
    logic                                 timeout_triggered;

    // Extract start/end addresses from packed parameters (generic for SLV_NB)
    logic [AXI_ADDR_W-1:0] slv_start_addr [0:SLV_NB-1];
    logic [AXI_ADDR_W-1:0] slv_end_addr   [0:SLV_NB-1];
    
    generate
    genvar i;
        for (i = 0; i < SLV_NB; i = i + 1) begin : SLV_ADDR_EXTRACT
            assign slv_start_addr[i] = SLV_START_ADDR[i*AXI_ADDR_W+:AXI_ADDR_W];
            assign slv_end_addr[i]   = SLV_END_ADDR[i*AXI_ADDR_W+:AXI_ADDR_W];
        end
    endgenerate


    ///////////////////////////////////////////////////////////////////////////
    // Write Address Channel
    ///////////////////////////////////////////////////////////////////////////

    // Address decoding
    generate
    genvar j;
    for (j = 0; j < SLV_NB; j = j + 1) begin : SLV_AW_ROUTE
        if (MST_ROUTES[j]==1'b1) begin : ROUTE_ON
            assign slv_aw_targeted[j] = (i_awch[0+:AXI_ADDR_W] >= slv_start_addr[j] &&
                                         i_awch[0+:AXI_ADDR_W] <= slv_end_addr[j]) ? 1'b1 : 1'b0;
        end else begin : ROUTE_OFF
            assign slv_aw_targeted[j] = 1'b0;
        end
    end
    endgenerate

    // AW channel assignments
    generate
    genvar n;
        for (n = 0; n < SLV_NB; n = n + 1) begin : SLV_AW_VALID
            assign o_awvalid[n] = (slv_aw_targeted[n]) ? i_awvalid & !bch_full & !wch_full : 1'b0;
        end
    endgenerate

    // Ready back-pressure selection
    always_comb begin

        if (slv_aw_targeted == '0)
            i_awready = aw_misrouting;
        else begin
            i_awready = '0;
            for (int i = 0; i < SLV_NB; i++)
                if (slv_aw_targeted[i])
                    i_awready = o_awready[i] & !wch_full;
        end
    end

    assign o_awch = i_awch;

    assign aw_misrouting_c = slv_aw_targeted=='0;

    // Create a fake ready handshake in case a master agent targets a
    // forbidden or undefined memory space
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            aw_misrouting <= 1'b0;
        end else if (srst) begin
            aw_misrouting <= 1'b0;
        end else begin
            if (aw_misrouting) begin
                aw_misrouting <= 1'b0;
            end else if (i_awvalid && aw_misrouting_c) begin
                aw_misrouting <= 1'b1;
            end
        end
    end


    ///////////////////////////////////////////////////////////////////////////
    // Write Data Channel
    ///////////////////////////////////////////////////////////////////////////

    // Store in a FIFO the slave agent targeted because address and data
    // channels are not always synchronized, data possibly coming later
    // after the write request
    axicb_scfifo
        #(
        .PASS_THRU  (0),
        .ADDR_WIDTH (8),
        .DATA_WIDTH (1 + SLV_NB + AXI_ID_W)
    )
    wch_gnt_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (1'b0),
        .data_in  ({aw_misrouting_c, slv_aw_targeted, i_awch[AXI_ADDR_W+:AXI_ID_W]}),
        .push     (i_awvalid & i_awready),
        .full     (wch_full),
        .data_out ({a_mr, slv_w_targeted, a_id}),
        .pull     (i_wvalid & i_wready & i_wlast),
        .empty    (wch_empty)
    );

    // Generic assignments for all slaves
    genvar k;
    generate
        for (k = 0; k < SLV_NB; k = k + 1) begin : SLV_W_VALID
            assign o_wvalid[k] = (!wch_empty & slv_w_targeted[k]) ? i_wvalid : 1'b0;
            assign o_wlast[k] = (!wch_empty & slv_w_targeted[k]) ? i_wlast : 1'b0;
        end
    endgenerate

    // Ready back-pressure selection
    always_comb begin

        // IDLE
        if (slv_w_targeted == '0 && wch_empty)
            i_wready = '0;
        // Targets an undefined or forbidden memory space
        else if (slv_w_targeted == '0 && !wch_empty)
            i_wready = '1;
        else begin
            i_wready = '0;
            for (int i = 0; i < SLV_NB; i++)
                if (!wch_empty && slv_w_targeted[i])
                    i_wready = o_wready[i];
        end
    end


    assign o_wch = i_wch;


    ///////////////////////////////////////////////////////////////////////////
    // Write Response channel
    ///////////////////////////////////////////////////////////////////////////

    // OoO ID Management
    axicb_slv_ooo
    #(
        .RD_PATH         (0),
        .AXI_ID_W        (AXI_ID_W),
        .SLV_NB          (SLV_NB),
        .MST_OSTDREQ_NUM (MST_OSTDREQ_NUM),
        .MST_ID_MASK     (MST_ID_MASK),
        .CCH_W           (BCH_W)
    )
    bresp_ooo
    (
        .aclk    (aclk),
        .aresetn (aresetn),
        .srst    (srst),
        .a_valid (i_wvalid & i_wlast & !wch_empty),
        .a_ready (i_wready),
        .a_full  (bch_full),
        .a_id    (a_id),
        .a_len   ('0),
        .a_ix    (slv_w_targeted),
        .a_mr    (a_mr),
        .c_en    (bch_en),
        .c_grant (bch_grant),
        .c_mr    (bch_mr),
        .c_id    (bch_id),
        .c_len   (/*unused*/),
        .c_valid (o_bvalid),
        .c_ready (i_bready),
        .c_ch    (o_bch),
        .c_end   (c_end)
    );

    assign c_end = i_bvalid & i_bready;

    // Control of the OoO ID management stage

    assign bch_en_c = |o_bvalid & i_bready;

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            bch_en_r <= '0;
        end else if (srst) begin
            bch_en_r <= '0;
        end else begin
            if (bch_grant=='0) bch_en_r <= 1'b1;
            else                bch_en_r <= 1'b0;
        end
    end

    // TODO: is it really usefull ? round-robin should pass anyway a
    // grant value if unmasked value > 0
    assign bch_en = bch_en_c | bch_en_r;

    // Switching logic for BRESP channel

    generate
    genvar m;
        for (m = 0; m < SLV_NB; m = m + 1) begin : SLV_B_READY
            assign o_bready[m] = bch_grant[m] & i_bready & !bch_mr & !timeout_triggered;
        end
    endgenerate


    ///////////////////////////////////////////////////////////////////////////
    // Timeout Mechanism Implementation
    ///////////////////////////////////////////////////////////////////////////
    
    // Global timeout watchdog.
    // Tracks whether any write response is outstanding.
    // This implementation uses one timer for all outstanding writes
    // and does not maintain a separate timer per transaction.
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
            
            // Track outstanding write responses normal operations & boundary guard protection
            if (!timeout_triggered) begin
                case ({ (i_awvalid && i_awready), (i_bvalid && i_bready) })
                    2'b10: begin
                        outstanding_tx_cnt <= outstanding_tx_cnt + 1'b1;
                    end
                    2'b01: begin
                        if (outstanding_tx_cnt != '0)
                            outstanding_tx_cnt <= outstanding_tx_cnt - 1'b1;
                    end
                    default: begin
                        outstanding_tx_cnt <= outstanding_tx_cnt;
                    end
                endcase
            end

            // Timer management & terminal state tracking
            if (outstanding_tx_cnt > 0 && !timeout_triggered) begin
                if (timeout_timer >= TIMEOUT_VAL - 1) begin
                    timeout_triggered <= 1'b1;
                end else if (|o_bvalid) begin
                    timeout_timer <= '0; // Reset timer if slave shows progress
                end else begin
                    timeout_timer <= timeout_timer + 1'b1;
                end
            end else if (timeout_triggered) begin
                // Update outstanding transaction count when timeout DECERR is accepted by Master
                if (i_bvalid && i_bready) begin
                    timeout_triggered <= 1'b0;
                    timeout_timer      <= '0;
                    if (outstanding_tx_cnt != '0)
                        outstanding_tx_cnt <= outstanding_tx_cnt - 1'b1;
                end
            end else begin
                timeout_timer <= '0;
            end
        end
    end


    always_comb begin

        i_bvalid = '0;
        i_bch = '0;

        if (TIMEOUT_ENABLE && timeout_triggered) begin
            i_bvalid = 1'b1;
            i_bch    = {2'h3, bch_id}; // Inject DECERR (2'h3) with active transaction ID
        end else begin
            // BVALID Signal
            if (bch_mr)
                i_bvalid = '1;
            else if (bch_grant == '0)
                i_bvalid = '0;
            else begin
                for (int i=0;i<SLV_NB;i++)
                    if (bch_grant[i])
                        i_bvalid = o_bvalid[i];
            end

            // BRESP / BUSER
            if (bch_mr)
                i_bch = {2'h3, bch_id} ;
            else if (bch_grant == '0)
                i_bch = '0;
            else begin
                for (int i=0;i<SLV_NB;i++)
                    if (bch_grant[i])
                        i_bch = o_bch[i*BCH_W+:BCH_W];
            end
        end
    end


endmodule

`resetall
