`timescale 1ns / 1ps

module axicb_slave_responder (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire        srst,
    input  wire        s_awvalid,
    output logic       s_awready,
    input  wire [7:0]  s_awch,
    input  wire        s_wvalid,
    output logic       s_wready,
    input  wire s_wlast,
    input  wire [7:0]  s_wch,
    output logic       s_bvalid,
    input  wire        s_bready,
    output logic [7:0] s_bch,
    input  wire        s_arvalid,
    output logic       s_arready,
    output logic       s_rvalid,
    input  wire        s_rready,
    output logic       s_rlast,
    output logic [7:0] s_rch
);

    bit [2:0] backpressure_weight = 0;

    initial begin
        s_awready = 0; s_wready  = 0; s_bvalid  = 0; s_bch     = 0;
        s_arready = 0; s_rvalid  = 0; s_rlast   = 0; s_rch     = 0;

        forever begin
            @(posedge aclk);
            if (aresetn && !srst) begin
                // Random stability generation for READY lines
                s_awready <= ($urandom_range(0, 7) >= backpressure_weight);
                s_wready  <= ($urandom_range(0, 7) >= backpressure_weight);
                s_arready <= ($urandom_range(0, 7) >= backpressure_weight);

                // Write Handling Logic
                if (s_awvalid && s_awready) begin
                    repeat($urandom_range(1, 3)) @(posedge aclk);
                    s_bvalid <= 1;
                    s_bch    <= 8'h00; 
                end
                if (s_bvalid && s_bready) begin
                    s_bvalid <= 0;
                end

                // Read Handling Logic
                if (s_arvalid && s_arready) begin
                    automatic int r_burst_len = $urandom_range(1, 8);
                    for (int beat = 0; beat < r_burst_len; beat++) begin
                        repeat($urandom_range(0, 2)) @(posedge aclk);
                        s_rvalid <= 1;
                        s_rlast  <= (beat == r_burst_len - 1);
                        s_rch    <= 8'hA0 + beat;
                        @(posedge aclk);
                        while (!s_rready) @(posedge aclk);
                        s_rvalid <= 0;
                        s_rlast  <= 0;
                    end
                end
            end
            else begin
                s_awready <= 0;
                s_wready  <= 0;
                s_bvalid  <= 0;
            end
        end
    end

endmodule
