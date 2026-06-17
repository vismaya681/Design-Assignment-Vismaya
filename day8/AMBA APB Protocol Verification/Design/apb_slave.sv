module apb_slave (
    input  logic        pclk,
    input  logic        presetn,
    input  logic [31:0] paddr,
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [31:0] pwdata,
    output logic        pready,
    output logic        pslverr,
    output logic [31:0] prdata
);

    // Internal Memory Space: 32 rows, each 32 bits wide
    logic [31:0] mem [0:31];

    // State Machine Enumeration Types
    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } state_t;

    state_t state;
    integer i;

    // Synchronous Protocol Sequential Block
    always_ff @(posedge pclk or negedge presetn)
    begin
        if(!presetn)
        begin
            state   <= IDLE;
            pready  <= 0;
            pslverr <= 0;
            prdata  <= 0;

            for(i=0; i<32; i++)
                mem[i] <= 0;
        end
        else
        begin
            case(state)

                //-------------------------------------------------------
                IDLE:
                //-------------------------------------------------------
                begin
                    pready  <= 0;
                    pslverr <= 0;

                    if(psel)
                        state <= SETUP;
                end

                //-------------------------------------------------------
                SETUP:
                //-------------------------------------------------------
                begin
                    pready <= 0;

                    if(psel && penable)
                        state <= ACCESS;
                end

                //-------------------------------------------------------
                ACCESS:
                //-------------------------------------------------------
                begin
                    pready <= 1;

                    if(paddr < 32)
                    begin
                        pslverr <= 0;

                        if(pwrite)
                        begin
                            mem[paddr] <= pwdata;
                        end
                        else
                        begin
                            prdata <= mem[paddr];
                        end
                    end
                    else
                    begin
                        pslverr <= 1;
                        prdata  <= 32'hDEAD_BEEF;
                    end

                    // Evaluate for back-to-back pipeline sequences
                    if(psel)
                        state <= SETUP; // Next transfer
                    else
                        state <= IDLE;  // No transfer
                end

                //-------------------------------------------------------
                default:
                //-------------------------------------------------------
                begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
