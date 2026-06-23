`timescale 1ns / 1ps

module axis_stat_counter #
(
    // Bit width of the AXI Stream Data bus (32 bits)
    parameter DATA_WIDTH = 32,
    // Bit width of the Byte-Keep bus (4 bits)
    parameter KEEP_WIDTH = (DATA_WIDTH/8),
    // Bit width of the output accumulator register (32-bit counter)
    parameter COUNT_WIDTH = 32
)
(
    input  wire                    clk,
    input  wire                    rst,

    /*
     * Snoop Monitor Interface (Tapped into the rate limiter output wires)
     */
    input  wire [DATA_WIDTH-1:0]   monitor_tdata,
    input  wire [KEEP_WIDTH-1:0]   monitor_tkeep,
    input  wire                    monitor_tvalid,
    input  wire                    monitor_tready,
    input  wire                    monitor_tlast,

    /*
     * Control & Handshake Interface (Communicates with your Control FSM)
     */
    input  wire                    trigger,
    output wire [COUNT_WIDTH-1:0]  status_byte_count,
    output wire                    status_valid
);

    // Internal tracking accumulators
    reg [COUNT_WIDTH-1:0] byte_count_reg = 0;
    reg [COUNT_WIDTH-1:0] status_byte_count_reg = 0;
    reg                    status_valid_reg = 1'b0;

    // Connect internal registers directly to output pins
    assign status_byte_count = status_byte_count_reg;
    assign status_valid      = status_valid_reg;

    // Detect a successful data transfer cycle on the snoop path
    wire data_handshake = monitor_tvalid && monitor_tready;

    // Integer conversion helper to count active bytes in tkeep
    integer i;
    reg [2:0] cycle_byte_count;

    always @(*) begin
        cycle_byte_count = 0;
        for (i = 0; i < KEEP_WIDTH; i = i + 1) begin
            if (monitor_tkeep[i]) begin
                cycle_byte_count = cycle_byte_count + 1'b1;
            end
        end
    end

    // Sequential Counter & Handshake Snapshot Engine
    always @(posedge clk) begin
        if (rst) begin
            byte_count_reg        <= 0;
            status_byte_count_reg <= 0;
            status_valid_reg      <= 1'b0;
        end else begin
            // Reset the validation pulse flag on every cycle unless a snapshot happens
            status_valid_reg <= 1'b0;

            // --- Accumulate Passing Traffic ---
            if (data_handshake) begin
                byte_count_reg <= byte_count_reg + cycle_byte_count;
            end

            // --- Capture Snapshot on FSM Trigger ---
            if (trigger) begin
                status_byte_count_reg <= byte_count_reg;
                status_valid_reg      <= 1'b1;
                byte_count_reg        <= 0; // Wipe counter clean for the next monitoring window
            end
        end
    end

endmodule
