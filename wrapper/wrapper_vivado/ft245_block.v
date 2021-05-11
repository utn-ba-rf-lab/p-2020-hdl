`define PARAMETER01 1
`define PARAMETER02 127
`define PARAMETER03 7
`define PARAMETER04 392
`define MODULATION 1
`define CLK_PERIOD 4

module ft245_block (
    input clk,
    input rst,

    // FT245 interface
    inout   [7:0] in_out_245,
    input   rxf_245,
    output  rx_245,
    input   txe_245,
    output  wr_245,

    // simple interface
    output reg  [7:0] rx_data_si,
    output reg  rx_valid_si,
    input       rx_ready_si,

    input [7:0] tx_data_si,
    input       tx_valid_si,
    output reg  tx_ready_si
);
    wire tx_oe_245;
    wire [7:0] in_245, out_245;

    ft245_fifo_interface #(
        .CLOCK_PERIOD_NS (`CLK_PERIOD)
    ) inst_ft245_fifo_interface (
        .clk            (clk),
        .rst            (rst),
        // ft245 rx interface
        .rx_data_245    (in_245),
        .rxf_245        (rxf_245),
        .rx_245         (rx_245),
        // ft245 tx interface
        .tx_data_245    (out_245),
        .txe_245        (txe_245),
        .wr_245         (wr_245),
        .tx_oe_245      (tx_oe_245),
        // simple interface
        .rx_data_si     (rx_data_si),
        .rx_valid_si      (rx_valid_si),
        .rx_ready_si      (rx_ready_si),
        .tx_data_si     (tx_data_si),
        .tx_valid_si      (tx_valid_si),
        .tx_ready_si      (tx_ready_si)
    );

    genvar h;
    generate
        for (h=0 ; h<8 ; h=h+1) begin
            SB_IO #(
                .PIN_TYPE(6'b101001),
                .PULLUP(1'b0)
            ) IO_PIN_INST (
                .PACKAGE_PIN (in_out_245[h]),
                .LATCH_INPUT_VALUE (),
                .CLOCK_ENABLE (),
                .INPUT_CLK (),
                .OUTPUT_CLK (),
                .OUTPUT_ENABLE (tx_oe_245),
                .D_OUT_0 (out_245[h]),
                .D_OUT_1 (),
                .D_IN_0 (in_245[h]),
                .D_IN_1 ()
            );
        end
    endgenerate
endmodule



