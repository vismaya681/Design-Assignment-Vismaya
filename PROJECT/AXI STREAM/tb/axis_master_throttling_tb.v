`timescale 1ns / 1ps

module axis_master_throttling_tb;

    parameter DATA_WIDTH = 32;
    parameter KEEP_WIDTH = (DATA_WIDTH/8);
    parameter CLK_PERIOD = 10; 

    // Testbench Drivers
    reg                    clk;
    reg                    rst;
    reg [31:0]             cfg_high_threshold_bytes;
    reg [31:0]             cfg_low_threshold_bytes;
    reg                    cfg_rate_limit_mode;

    // Upstream Inputs
    reg [DATA_WIDTH-1:0]   s_axis_tdata;
    reg [KEEP_WIDTH-1:0]   s_axis_tkeep;
    reg                    s_axis_tvalid;
    wire                   s_axis_tready;
    reg                    s_axis_tlast;

    // Downstream Outputs
    wire [DATA_WIDTH-1:0]  m_axis_tdata;
    wire [KEEP_WIDTH-1:0]  m_axis_tkeep;
    wire                   m_axis_tvalid;
    reg                    m_axis_tready;
    wire                   m_axis_tlast;

    // Instantiate Unit Under Test (Top Module)
    axi_stream_rate_limiter_top #(
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .cfg_high_threshold_bytes(cfg_high_threshold_bytes),
        .cfg_low_threshold_bytes(cfg_low_threshold_bytes),
        .cfg_rate_limit_mode(cfg_rate_limit_mode),
        
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // Continuous Clock Generator 
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        // =====================================================================
        // BOOT & INITIALIZATION (0ns to 150ns)
        // =====================================================================
        clk = 0; rst = 1; s_axis_tvalid = 0; s_axis_tdata = 0; s_axis_tkeep = 0; s_axis_tlast = 0;
        cfg_high_threshold_bytes = 32'd40; // Low byte limit to force statistical throttling
        cfg_low_threshold_bytes  = 32'd10;
        cfg_rate_limit_mode      = 1'b0;   
        m_axis_tready            = 1'b1;   // Downstream is open and ready
        
        #(CLK_PERIOD * 10);
        rst = 0; // Release Reset
        #(CLK_PERIOD * 5);

        // =====================================================================
        // PHASE 1: STATISTICAL THROTTLING ACTIVE (150ns onwards)
        // =====================================================================
        $display("[%0tns] [TB] PHASE 1: Flooding traffic to trip Statistical Throttling...", $time);
        s_axis_tvalid = 1'b1;
        s_axis_tkeep  = 4'hf;
        
        // Push data to exceed 40 bytes. m_axis_tvalid will begin chopping/throttling.
        repeat (30) begin
            s_axis_tdata = s_axis_tdata + 32'h1;
            #(CLK_PERIOD);
        end
     // =====================================================================
        // PHASE 2: STATISTICAL RECOVERY (Let it clear completely)
        // =====================================================================
        $display("[%0tns] [TB] PHASE 2: Stopping input to let Statistical module recover...", $time);
        s_axis_tvalid = 1'b0; 
        
        #(CLK_PERIOD * 150); // INCREASED: Gives the credit bucket plenty of time to empty out

        // =====================================================================
        // PHASE 3: EMERGENCY FIFO THROTTLING ACTIVATION
        // =====================================================================
        $display("[%0tns] [TB] PHASE 3: DOWNSTREAM STALL! Slamming ready LOW...", $time);
        
        // Turn off statistical limits so it doesn't try to pulse at 25%
        cfg_high_threshold_bytes = 32'hFFFF_FFFF; 
        
        // Force the downstream master ready to 0 to create an absolute blockade
        m_axis_tready = 1'b0; 
        
        // Flood the input continuously
        s_axis_tvalid = 1'b1; 
        
        // Push 450 items continuously on a flat-low tready to guarantee we pass 410
        repeat (450) begin
            s_axis_tdata = s_axis_tdata + 32'h1;
            #(CLK_PERIOD);
        end
        s_axis_tvalid = 1'b0; // Stop upstream flood

        // =====================================================================
        // PHASE 4: EMERGENCY FIFO RECOVERY (Drain back to 0)
        // =====================================================================
        $display("[%0tns] [TB] PHASE 4: RECOVERY! Re-opening downstream path...", $time);
        m_axis_tready = 1'b1; // Open the output valve!
        
        #(CLK_PERIOD * 450); // Let the internal FIFO drain out every single word completely

        $display("[%0tns] [TB] Complete Multi-Phase Simulation Cycle Finished.", $time);
        
        // Keep running clock to maintain the visual timeline view
        forever #(CLK_PERIOD);
    end

endmodule
