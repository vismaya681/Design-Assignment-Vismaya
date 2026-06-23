`timescale 1ns / 1ps

module axicb_master_driver (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire        srst,
    output logic       m_awvalid,
    input  wire        m_awready,
    output logic [7:0] m_awch,
    output logic       m_wvalid,
    input  wire        m_wready,
    output logic       m_wlast,
    output logic [7:0] m_wch,
    input  wire        m_bvalid,
    output logic       m_bready
);

    // Initialized to prevent X-propagation in Vivado
    initial begin
        m_awvalid = 0;
        m_awch    = 0;
        m_wvalid  = 0;
        m_wlast   = 0;
        m_wch     = 0;
        m_bready  = 0;
    end

    // Automatic task for clean concurrent execution in forks
    task automatic drive_write_burst(
        input bit [7:0] addr,
        input int       burst_len,
        input bit [3:0] master_id
    );
        begin
            $display("[TIME: %0t ns] [MASTER %0d] --> Initiating Write to Addr: 0x%h", $time, master_id, addr);
            
            // 1. Address Write Phase
            m_awvalid = 1;
            m_awch    = addr;
            @(posedge aclk);
            while (!m_awready) @(posedge aclk);
            m_awvalid = 0;
            $display("[TIME: %0t ns] [MASTER %0d]   STAGE OK: Address Accepted (AWREADY)", $time, master_id);

            // 2. Data Write Burst Phase
            for (int beat = 0; beat < burst_len; beat++) begin
                m_wvalid = 1;
                m_wch    = (master_id << 4) | beat;
                m_wlast  = (beat == burst_len - 1);
                @(posedge aclk);
                while (!m_wready) @(posedge aclk);
            end
            m_wvalid = 0;
            m_wlast  = 0;
            $display("[TIME: %0t ns] [MASTER %0d]   STAGE OK: Data Burst Sent (WREADY)", $time, master_id);

            // 3. Response Status Capture Handshake
            m_bready = 1;
            while (!m_bvalid) @(posedge aclk);
            @(posedge aclk);
            m_bready = 0;
            $display("[TIME: %0t ns] [MASTER %0d]   STAGE OK: Write Response Complete (BVALID)", $time, master_id);
        end
    endtask

endmodule
