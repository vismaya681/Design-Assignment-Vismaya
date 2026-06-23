`timescale 1ns / 1ps

module rate_control_fsm #
(
    parameter COUNTER_WIDTH = 32,
    parameter COOLDOWN_CYCLES = 5000
)
(
    input  wire                         clk,
    input  wire                         rst,
    
    input  wire [COUNTER_WIDTH-1:0]     cfg_high_threshold_bytes,
    input  wire [COUNTER_WIDTH-1:0]     cfg_low_threshold_bytes,
    
    input  wire                         fifo_prog_full,
    
    output reg                          stat_trigger,
    input  wire [COUNTER_WIDTH-1:0]     stat_byte_count,
    input  wire                         stat_valid,
  
    output reg [7:0]                    rate_limit_num,
    output reg [7:0]                    rate_limit_denom
);

    localparam STATE_IDLE     = 3'b001;
    localparam STATE_THROTTLE = 3'b010;
    localparam STATE_RECOVERY = 3'b100;
    
    reg [2:0] state = STATE_IDLE;
    reg [2:0] next_state;
    reg [15:0] cooldown_timer = 16'd0;

    // =========================================================================
    // 1. Synchronous State & Configuration Output Update Block
    // =========================================================================
    always @(posedge clk) begin
        if (rst) begin
            state            <= STATE_IDLE;
            cooldown_timer   <= 16'd0;
            
            rate_limit_num   <= 8'd1;
            rate_limit_denom <= 8'd1;
        end else begin
            state <= next_state;
            
            // Control Cooldown Timer
            if (state == STATE_RECOVERY) begin
                if (cooldown_timer > 0)
                    cooldown_timer <= cooldown_timer - 1'b1;
            end else begin
                cooldown_timer <= COOLDOWN_CYCLES;
            end

            // Drive outputs synchronously based on the NEXT state to avoid lag
            case (next_state)
                STATE_IDLE: begin
                    rate_limit_num   <= 8'd1; // 1/1 = 100% capacity
                    rate_limit_denom <= 8'd1;
                end
                
                STATE_THROTTLE: begin
                    rate_limit_num   <= 8'd1; // 1/4 = 25% capacity
                    rate_limit_denom <= 8'd4;
                end
                
                STATE_RECOVERY: begin
                    rate_limit_num   <= 8'd1; // 1/2 = 50% capacity
                    rate_limit_denom <= 8'd2;
                end
                
                default: begin
                    rate_limit_num   <= 8'd1;
                    rate_limit_denom <= 8'd1;
                end
            endcase
        end
    end
    
    // =========================================================================
    // 2. Combinational Next-State Evaluation Matrix
    // =========================================================================
    always @(*) begin
        next_state = state;
        stat_trigger = 1'b0;
        
        case(state)
            STATE_IDLE: begin
                if (fifo_prog_full) begin
                    next_state = STATE_THROTTLE;
                end else if (stat_valid) begin
                    if (stat_byte_count > cfg_high_threshold_bytes) begin
                        next_state = STATE_THROTTLE;
                    end else begin
                        stat_trigger = 1'b1;
                    end
                end
            end
            
            STATE_THROTTLE: begin
                if (stat_valid) begin
                    if (stat_byte_count < cfg_low_threshold_bytes && !fifo_prog_full) begin
                        next_state = STATE_RECOVERY;
                    end else begin
                        stat_trigger = 1'b1;
                    end
                end
            end
            
            STATE_RECOVERY: begin
                if (fifo_prog_full) begin
                    next_state = STATE_THROTTLE;
                end else if (stat_valid) begin
                    if (stat_byte_count > cfg_high_threshold_bytes) begin
                        next_state = STATE_THROTTLE;
                    end else begin
                        stat_trigger = 1'b1;
                    end
                end
                
                if (cooldown_timer == 16'd0) begin
                    next_state = STATE_IDLE;
                end
            end
            
            default: next_state = STATE_IDLE;
        endcase
    end

endmodule
