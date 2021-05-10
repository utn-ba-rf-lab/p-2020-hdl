
`timescale 1ns/1ps

module ft245_fifo_interface #(
    parameter CLOCK_PERIOD_NS = 8
)(
    input clk,
    input rst,

    // ft245 rx interface
    input [7:0] rx_data_245,
    input rxf_245,
    output reg rx_245,
    // ft245 tx interface
    output reg [7:0] tx_data_245,
    input txe_245,
    output reg wr_245,
    output reg tx_oe_245,

    // simple interface rx
    output reg [7:0] rx_data_si,
    output reg rx_valid_si,
    input rx_ready_si,
    // simple interface tx
    input [7:0] tx_data_si,
    input tx_valid_si,
    output reg tx_ready_si
);

    localparam WAIT_TIME_RX = 30.0;
    localparam INACTIVE_TIME_RX = 14.0; // 14.0;
    localparam SETUP_TIME_TX = 5.0;
    localparam HOLD_TIME_TX = 5.0;
    localparam ACTIVE_TIME_TX = 30.0;

    localparam CNT_WAIT_RX = $rtoi($ceil(WAIT_TIME_RX/CLOCK_PERIOD_NS));
    localparam CNT_INACTIVE_RX = $rtoi($ceil(INACTIVE_TIME_RX/CLOCK_PERIOD_NS))+2; // <-- this is important
                                                            // the "+2" is because of the delay
    localparam CNT_SETUP_TX = $rtoi($ceil(SETUP_TIME_TX/CLOCK_PERIOD_NS));
    localparam CNT_ACTIVE_TX = $rtoi($ceil(ACTIVE_TIME_TX/CLOCK_PERIOD_NS))+4;
    localparam MAX_CNT = CNT_WAIT_RX;

    initial begin
        //$display("CLOCK_PERIOD_NS:: CLOCK_PERIOD_NS=%s", CLOCK_PERIOD_NS);
        $display("CNT_WAIT_RX:: CNT_WAIT_RX=%d", CNT_WAIT_RX);
        $display("CNT_INACTIVE_RX:: CNT_INACTIVE_RX=%d", CNT_INACTIVE_RX);
        $display("CNT_SETUP_TX:: CNT_SETUP_TX=%d", CNT_SETUP_TX);
        $display("CNT_ACTIVE_TX:: CNT_ACTIVE_TX=%d", CNT_ACTIVE_TX);
        $display("MAX_CNT:: MAX_CNT=%d", MAX_CNT);
    end

    localparam ST_IDLE = 0;
    localparam ST_WAIT_RX = 1;
    localparam ST_INACTIVE_RX =2;
    localparam ST_SETUP_TX = 3;
    localparam ST_WAIT_TX = 4;

    reg [2:0] state;
    reg [$clog2(MAX_CNT):0] cnt;
    
    reg rxf_245_i=0, rxf_245_ii=0, txe_245_i=0, txe_245_ii=0, rx_valid_si2;

    always @(posedge clk) begin
        rx_valid_si <= 1'b0;

        if (rst == 1'b1) begin
            tx_data_245 <= 0;
            rx_245 <= 1'b1;
            wr_245 <= 1'b1;
            tx_oe_245 <= 1'b0;
            rx_data_si <= 0;
            rx_valid_si2 <= 1'b0;
            tx_ready_si <= 1'b0;
            state <= ST_IDLE;
            cnt <= 0;
            rxf_245_i <= 1'b1;
            rxf_245_ii <= 1'b1;
            txe_245_i <= 1'b1;
            txe_245_ii <= 1'b1;
        end else begin
            rxf_245_i <= rxf_245;
            rxf_245_ii <= rxf_245_i;
            txe_245_i <= txe_245;
            txe_245_ii <= txe_245_i;
            wr_245 <= 1'b1;
            tx_ready_si <= 1'b0;
            case (state)
                ST_IDLE:
                begin
                    if (rxf_245_ii == 1'b0) begin
                        rxf_245_i <= 1'b1;
                        rxf_245_ii <= 1'b1;
                        txe_245_i <= 1'b1;
                        txe_245_ii <= 1'b1;
                        rx_245 <= 1'b0;
                        cnt <= 0;
                        state <= ST_WAIT_RX;
                    end else if(txe_245_ii == 1'b0 && tx_valid_si == 1'b1) begin
                        rxf_245_i <= 1'b1;
                        rxf_245_ii <= 1'b1;
                        txe_245_i <= 1'b1;
                        txe_245_ii <= 1'b1;
                        tx_data_245 <= tx_data_si;
                        tx_oe_245 <= 1'b1;
                        tx_ready_si <= 1'b1;
                        state <= ST_SETUP_TX;
                        cnt <= CNT_SETUP_TX;
                    end
                end

                ST_WAIT_RX:
                begin
                    cnt <= cnt + 1;
                    if (cnt >= CNT_WAIT_RX-1) begin
                        rx_245 <= 1'b1;
                        state <= ST_INACTIVE_RX;
                        cnt <= 0;
                        rx_data_si <= rx_data_245;
                        rx_valid_si2 <= 1'b1;
                    end
                end

                ST_INACTIVE_RX:
                begin
                    if (cnt < CNT_INACTIVE_RX) cnt <= cnt + 1;
                    if ((cnt >= CNT_INACTIVE_RX-1) && (rx_ready_si & rx_valid_si2)) begin
                        rx_valid_si2 <= 1'b0;
                        rx_valid_si <= 1'b1;
                        state <= ST_IDLE;
                    end
                end

                ST_SETUP_TX:
                begin
                    cnt <= cnt + 1;
                    if(cnt >= CNT_SETUP_TX) begin
                        state <= ST_WAIT_TX;
                        wr_245 <= 1'b0;
                        cnt <= 0;
                    end
                end

                ST_WAIT_TX: // Espera ACTIVE_TIME_TX
                begin
                    cnt <= cnt + 1;
                    wr_245 <= 1'b0;
                    if (cnt >= CNT_ACTIVE_TX-1) begin
                        cnt <= 0;
                        tx_oe_245 <= 1'b0;
                        state <= ST_IDLE;
                        wr_245 <= 1'b1;
                    end
                end

                default:  rx_245 <= 1'b1;
            endcase
        end
    end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("waveform.vcd");
  $dumpvars (0,ft245_interface);
  #1;
end
`endif

endmodule
