`timescale 1ns / 1ps

module axi_stream_rate_limiter_top #
(
    parameter DATA_WIDTH = 32,
    parameter KEEP_WIDTH = (DATA_WIDTH/8)
)
(
    input  wire                    clk,
    input  wire                    rst,

    // Static Configuration Controls
    input  wire [31:0]             cfg_high_threshold_bytes,
    input  wire [31:0]             cfg_low_threshold_bytes,
    input  wire                    cfg_rate_limit_mode,

    // Upstream Slave Interface (Input Gate)
    input  wire [DATA_WIDTH-1:0]   s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]   s_axis_tkeep,
    input  wire                    s_axis_tvalid,
    output wire                    s_axis_tready,
    input  wire                    s_axis_tlast,

    // Downstream Master Interface (Output Gate)
    output wire [DATA_WIDTH-1:0]   m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]   m_axis_tkeep,
    output wire                    m_axis_tvalid,
    input  wire                    m_axis_tready,
    output wire                    m_axis_tlast
);

    // =========================================================================
    // Internal Interconnect Pipeline Wires
    // =========================================================================
    
    // 1. From Input Register Slice to FIFO
    wire [DATA_WIDTH-1:0] slice_to_fifo_tdata;
    wire [KEEP_WIDTH-1:0] slice_to_fifo_tkeep;
    wire                  slice_to_fifo_tvalid;
    wire                  slice_to_fifo_tready;
    wire                  slice_to_fifo_tlast;

    // 2. From FIFO to Rate Limiter
    wire [DATA_WIDTH-1:0] fifo_to_limiter_tdata;
    wire [KEEP_WIDTH-1:0] fifo_to_limiter_tkeep;
    wire                  fifo_to_limiter_tvalid;
    wire                  fifo_to_limiter_tready;
    wire                  fifo_to_limiter_tlast;

    // 3. Control Feedback Lines (FSM <-> Statistics Counter & FIFO)
    wire                  fifo_to_fsm_watermark;
    wire                  ctrl_stat_trigger;
    wire [31:0]           stat_byte_count_out;
    wire                  stat_update_valid;
    wire [7:0]            dynamic_num;
    wire [7:0]            dynamic_denom;

    // =========================================================================
    // Stage 1: Input Register Slice (Akshara's Module)
    // =========================================================================
    axis_reg_slice #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_slice_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        
        .m_axis_tdata(slice_to_fifo_tdata),
        .m_axis_tkeep(slice_to_fifo_tkeep),
        .m_axis_tvalid(slice_to_fifo_tvalid),
        .m_axis_tready(slice_to_fifo_tready),
        .m_axis_tlast(slice_to_fifo_tlast)
    );

    // =========================================================================
    // Stage 2: Elastic Buffer FIFO Array (Vismaya's Module)
    // =========================================================================
    axis_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(9) // 512 Word Deep Memory Array
    ) elastic_fifo_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(slice_to_fifo_tdata),
        .s_axis_tkeep(slice_to_fifo_tkeep),
        .s_axis_tvalid(slice_to_fifo_tvalid),
        .s_axis_tready(slice_to_fifo_tready),
        .s_axis_tlast(slice_to_fifo_tlast),
        
        .m_axis_tdata(fifo_to_limiter_tdata),
        .m_axis_tkeep(fifo_to_limiter_tkeep),
        .m_axis_tvalid(fifo_to_limiter_tvalid),
        .m_axis_tready(fifo_to_limiter_tready),
        .m_axis_tlast(fifo_to_limiter_tlast),
        
        .fifo_watermark_80(fifo_to_fsm_watermark)
    );

    // =========================================================================
    // Stage 3: Fractional Rate Limiter Throttling Valve (Ammar's Core)
    // =========================================================================
    axis_rate_limit #(
        .DATA_WIDTH(DATA_WIDTH)
    ) rate_limiter_inst (
        .clk(clk),
        .rst(rst),
        .s_axis_tdata(fifo_to_limiter_tdata),
        .s_axis_tkeep(fifo_to_limiter_tkeep),
        .s_axis_tvalid(fifo_to_limiter_tvalid),
        .s_axis_tready(fifo_to_limiter_tready),
        .s_axis_tlast(fifo_to_limiter_tlast),
        
        // Connects directly to top-level external Master outputs
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        
        .rate_num(dynamic_num),
        .rate_denom(dynamic_denom),
        .mode(cfg_rate_limit_mode)
    );

    // =========================================================================
    // Stage 4: Windowed Traffic Statistics Exit Monitor
    // =========================================================================
    axis_stat_counter #(
        .DATA_WIDTH(DATA_WIDTH),
        .COUNT_WIDTH(32)
    ) statistics_counter_inst (
        .clk(clk),
        .rst(rst),
        .monitor_tdata(m_axis_tdata),
        .monitor_tkeep(m_axis_tkeep),
        .monitor_tvalid(m_axis_tvalid),
        .monitor_tready(m_axis_tready),
        .monitor_tlast(m_axis_tlast),
        
        .trigger(ctrl_stat_trigger),
        .status_byte_count(stat_byte_count_out),
        .status_valid(stat_update_valid)
    );

    // =========================================================================
    // Stage 5: System Closed-Loop Control Decision FSM
    // =========================================================================
    rate_control_fsm #(
        .COUNTER_WIDTH(32)
    ) control_fsm_inst (
        .clk(clk),
        .rst(rst),
        .cfg_high_threshold_bytes(cfg_high_threshold_bytes),
        .cfg_low_threshold_bytes(cfg_low_threshold_bytes),
        .fifo_prog_full(fifo_to_fsm_watermark),
        .stat_trigger(ctrl_stat_trigger),
        .stat_byte_count(stat_byte_count_out),
        .stat_valid(stat_update_valid),
        .rate_limit_num(dynamic_num),
        .rate_limit_denom(dynamic_denom)
    );

endmodule
