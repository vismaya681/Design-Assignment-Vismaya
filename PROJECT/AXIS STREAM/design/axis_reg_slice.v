`timescale 1ns / 1ps

module axis_reg_slice #
(
    parameter DATA_WIDTH = 32,
    parameter KEEP_WIDTH = (DATA_WIDTH/8)
)
(
    input  wire                    clk,
    input  wire                    rst,

    // Upstream Slave Ports
    input  wire [DATA_WIDTH-1:0]   s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]   s_axis_tkeep,
    input  wire                    s_axis_tvalid,
    output wire                    s_axis_tready,
    input  wire                    s_axis_tlast,

    // Downstream Master Ports (Feeds directly to Vismaya's FIFO)
    output wire [DATA_WIDTH-1:0]   m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]   m_axis_tkeep,
    output wire                    m_axis_tvalid,
    input  wire                    m_axis_tready,
    output wire                    m_axis_tlast
);

    // Two-stage storage registers (The Timing Bulkhead Pipeline registers)
    reg [DATA_WIDTH-1:0] data_reg  = 0;
    reg [KEEP_WIDTH-1:0] keep_reg  = 0;
    reg                  valid_reg = 1'b0;
    reg                  last_reg  = 1'b0;

    reg [DATA_WIDTH-1:0] temp_data_reg  = 0;
    reg [KEEP_WIDTH-1:0] temp_keep_reg  = 0;
    reg                  temp_valid_reg = 1'b0;
    reg                  temp_last_reg  = 1'b0;

    // Ready signal is driven by whether our auxiliary storage register is empty
    assign s_axis_tready = !temp_valid_reg;

    // Output routing maps directly out of the primary timing pipeline registers
    assign m_axis_tdata  = valid_reg ? data_reg  : s_axis_tdata;
    assign m_axis_tkeep  = valid_reg ? keep_reg  : s_axis_tkeep;
    assign m_axis_tvalid = valid_reg ? 1'b1      : s_axis_tvalid;
    assign m_axis_tlast  = valid_reg ? last_reg  : s_axis_tlast;

  
    always @(posedge clk) begin
        if (rst) begin
            valid_reg      <= 1'b0;
            temp_valid_reg <= 1'b0;
            data_reg       <= 0;
            keep_reg       <= 0;
            last_reg       <= 1'b0;
            temp_data_reg  <= 0;
            temp_keep_reg  <= 0;
            temp_last_reg  <= 1'b0;
        end else begin
            // Handle transferring data from primary buffer to secondary buffer if stalled
            if (m_axis_tready) begin
                if (temp_valid_reg) begin
                    valid_reg      <= 1'b1;
                    data_reg       <= temp_data_reg;
                    keep_reg       <= temp_keep_reg;
                    last_reg       <= temp_last_reg;
                    temp_valid_reg <= 1'b0;
                end else begin
                    valid_reg      <= 1'b0;
                end
            end else if (s_axis_tvalid && s_axis_tready) begin
                if (valid_reg) begin
                    temp_valid_reg <= 1'b1;
                    temp_data_reg  <= s_axis_tdata;
                    temp_keep_reg  <= s_axis_tkeep;
                    temp_last_reg  <= s_axis_tlast;
                end else begin
                    valid_reg      <= 1'b1;
                    data_reg       <= s_axis_tdata;
                    keep_reg       <= s_axis_tkeep;
                    last_reg       <= s_axis_tlast;
                end
            end
        end
    end

endmodule
