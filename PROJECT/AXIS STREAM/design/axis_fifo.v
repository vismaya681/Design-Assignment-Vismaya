
`timescale 1ns / 1ps

module axis_fifo #
(
    parameter DATA_WIDTH = 32,
    parameter KEEP_WIDTH = (DATA_WIDTH/8),
    parameter FIFO_DEPTH = 512,
    parameter ADDR_WIDTH = $clog2(FIFO_DEPTH)
)
(
    input  wire                    clk,
    input  wire                    rst,

    /*
     * AXI Stream Slave Interface
     */
    input  wire [DATA_WIDTH-1:0]   s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]   s_axis_tkeep,
    input  wire                    s_axis_tvalid,
    output wire                    s_axis_tready,
    input  wire                    s_axis_tlast,

    /*
     * AXI Stream Master Interface
     */
    output wire [DATA_WIDTH-1:0]   m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]   m_axis_tkeep,
    output wire                    m_axis_tvalid,
    input  wire                    m_axis_tready,
    output wire                    m_axis_tlast,

    /*
     * Congestion Control Status Flag
     */
    output wire                    fifo_watermark_80
);

    localparam PAYLOAD_WIDTH = DATA_WIDTH + KEEP_WIDTH + 1;
    reg [PAYLOAD_WIDTH-1:0] mem [FIFO_DEPTH-1:0];

    reg [ADDR_WIDTH:0] wr_ptr_reg = 0;
    reg [ADDR_WIDTH:0] rd_ptr_reg = 0;

    reg [DATA_WIDTH-1:0] m_axis_tdata_reg  = 0;
    reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg  = 0;
    reg                  m_axis_tvalid_reg = 1'b0;
    reg                  m_axis_tlast_reg  = 1'b0;

    reg [DATA_WIDTH-1:0] temp_m_axis_tdata_reg  = 0;
    reg [KEEP_WIDTH-1:0] temp_m_axis_tkeep_reg  = 0;
    reg                  temp_m_axis_tvalid_reg = 1'b0;
    reg                  temp_m_axis_tlast_reg  = 1'b0;

    wire empty = (wr_ptr_reg == rd_ptr_reg);
    wire full  = (wr_ptr_reg[ADDR_WIDTH-1:0] == rd_ptr_reg[ADDR_WIDTH-1:0]) && 
                 (wr_ptr_reg[ADDR_WIDTH] != rd_ptr_reg[ADDR_WIDTH]);

    wire write = s_axis_tvalid && s_axis_tready;
    reg  read = 1'b0;

    assign s_axis_tready = !full;
    assign m_axis_tvalid = m_axis_tvalid_reg;

    assign m_axis_tdata  = m_axis_tdata_reg;
    assign m_axis_tkeep  = m_axis_tkeep_reg;
    assign m_axis_tlast  = m_axis_tlast_reg;

    // =========================================================================
    // 80% Watermark Evaluation: 512 words * 0.80 = 410 words
    // =========================================================================
    wire [ADDR_WIDTH:0] fifo_occupancy = wr_ptr_reg - rd_ptr_reg;
    assign fifo_watermark_80 = (fifo_occupancy >= 9'd410);

    // Memory Write Operation
  integer i;

    // Memory Write & Reset Initialization Operation
    always @(posedge clk) begin
        if (rst) begin
            // Explicitly ground every single memory slot to kill the red X state at boot
            for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
                mem[i] <= 0;
            end
        end else if (write) begin
            mem[wr_ptr_reg[ADDR_WIDTH-1:0]] <= {s_axis_tlast, s_axis_tkeep, s_axis_tdata};
        end
    end

    // Main Control & Pointer FSM
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr_reg             <= 0;
            rd_ptr_reg             <= 0;
            m_axis_tvalid_reg      <= 1'b0;
            temp_m_axis_tvalid_reg <= 1'b0;
        end else begin
            if (write) begin
                wr_ptr_reg <= wr_ptr_reg + 1'b1;
            end

            read = 1'b0;
            if (!empty) begin
                if (!m_axis_tvalid_reg || m_axis_tready || !temp_m_axis_tvalid_reg) begin
                    read = 1'b1;
                    rd_ptr_reg <= rd_ptr_reg + 1'b1;
                end
            end

            if (m_axis_tready) begin
                if (temp_m_axis_tvalid_reg) begin
                    m_axis_tvalid_reg      <= 1'b1;
                    m_axis_tdata_reg       <= temp_m_axis_tdata_reg;
                    m_axis_tkeep_reg       <= temp_m_axis_tkeep_reg;
                    m_axis_tlast_reg       <= temp_m_axis_tlast_reg;
                    temp_m_axis_tvalid_reg <= 1'b0;
                end else if (!empty && (!m_axis_tvalid_reg || !temp_m_axis_tvalid_reg)) begin
                    m_axis_tvalid_reg      <= 1'b1;
                    {m_axis_tlast_reg, m_axis_tkeep_reg, m_axis_tdata_reg} <= mem[rd_ptr_reg[ADDR_WIDTH-1:0]];
                end else begin
                    m_axis_tvalid_reg      <= 1'b0;
                end
            end else begin
                if (read) begin
                    if (m_axis_tvalid_reg) begin
                        temp_m_axis_tvalid_reg <= 1'b1;
                        temp_m_axis_tdata_reg  <= mem[rd_ptr_reg[ADDR_WIDTH-1:0]][DATA_WIDTH-1:0];
                        temp_m_axis_tkeep_reg  <= mem[rd_ptr_reg[ADDR_WIDTH-1:0]][DATA_WIDTH+KEEP_WIDTH-1:DATA_WIDTH];
                        temp_m_axis_tlast_reg  <= mem[rd_ptr_reg[ADDR_WIDTH-1:0]][PAYLOAD_WIDTH-1];
                    end else begin
                        m_axis_tvalid_reg      <= 1'b1;
                        {m_axis_tlast_reg, m_axis_tkeep_reg, m_axis_tdata_reg} <= mem[rd_ptr_reg[ADDR_WIDTH-1:0]];
                    end
                end
            end
        end
    end

endmodule
