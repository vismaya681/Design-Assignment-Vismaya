module axis_rate_limit #
(
    parameter DATA_WIDTH = 32,
    parameter KEEP_WIDTH = (DATA_WIDTH/8)
)
(
    input  wire                  clk,
    input  wire                  rst,

    // Upstream Slave Interface (From FIFO)
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0] s_axis_tkeep,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    input  wire                  s_axis_tlast,

    // Downstream Master Interface (To Output Pins)
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire [KEEP_WIDTH-1:0] m_axis_tkeep,
    output wire                  m_axis_tvalid,
    input  wire                  m_axis_tready,
    output wire                  m_axis_tlast,

    // Dynamic Fractional Control Inputs from FSM
    input  wire [7:0]            rate_num,
    input  wire [7:0]            rate_denom,
    input  wire                  mode
);

    // 12-bit Credit Accumulator
    reg [11:0] credit_accumulator = 0;
    
    // Check if FSM configuration inputs are stable and valid numbers
    wire inputs_are_valid = (rate_denom !== 8'bxxxxxxxx) && (rate_num !== 8'bxxxxxxxx) && (rate_denom > 0);
    

    wire [7:0] safe_denom = inputs_are_valid ? rate_denom : 8'd1;
    wire [7:0] safe_num   = inputs_are_valid ? rate_num   : 8'd1;

    // Evaluate structural credit limits safely
    wire has_enough_credit = !inputs_are_valid ? 1'b1 : (credit_accumulator >= safe_denom);
    
    // Drive handshakes
    assign s_axis_tready = m_axis_tready && has_enough_credit;
    assign m_axis_tvalid = s_axis_tvalid && has_enough_credit;
    
    // Direct data pass-through
    assign m_axis_tdata  = s_axis_tdata;
    assign m_axis_tkeep  = s_axis_tkeep;
    assign m_axis_tlast  = s_axis_tlast;

    // Synchronous Credit Engine with X-State Protection Gateways
    always @(posedge clk) begin
        if (rst) begin
            credit_accumulator <= 12'd0;
        end else if (!inputs_are_valid) begin
            // Hold accumulator safe at zero if FSM is still booting/initializing
            credit_accumulator <= 12'd0;
        end else begin
            if (s_axis_tvalid && m_axis_tready) begin
                if (has_enough_credit) begin
                    // Safe subtraction using validated registers
                    credit_accumulator <= (credit_accumulator + safe_num) - safe_denom;
                end else begin
                    credit_accumulator <= credit_accumulator + safe_num;
                end
            end else if (!s_axis_tvalid && has_enough_credit && credit_accumulator > 0) begin
                credit_accumulator <= credit_accumulator - 1'b1;
            end else begin
                credit_accumulator <= credit_accumulator + safe_num;
            end
        end
    end

endmodule
