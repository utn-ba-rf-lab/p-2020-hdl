`include "../inc/module_params.v"

module top_level (
    // basics
    input   hwclk,
    input   rst,

    // i am alive
    output  [7:0] leds,

    // FT245 interface
    inout   [7:0] in_out_245,
    input   rxf_245,
    output  rx_245,
    input   txe_245,
    output  wr_245,

    // output
    output  pwm_diff_p,
    output  pwm_diff_n,
    output  pwm_pin,
    
//    output  sdata,
    output  bclk,
    output  nsync,

    // --- test ---
    output  symb_clk,
    output  fifo_empty,

//    output  fake_pwm,
//    output  fake_sdata,
//    output  fake_bclk,
//    output  fake_nsync
);
    /***************************************************************************
     * signals
     ***************************************************************************
     */
    reg clk;
    reg [7:0] led_reg;

    // FT245 - Simple Interface
    wire rx_valid_si, rx_ready_si;
    wire tx_valid_si, tx_ready_si;
    wire [7:0] rx_data_si, tx_data_si;

    // Inteface between fifo and modulator
    wire [7:0] sample;
    wire read_sample;

    // Inteface between control_unit and deco_unit
    wire tx, rx;
    wire [7:0] data_tx, data_rx;

    // outputs
    reg [26:0] count;
    wire pwm_signal, sdata_signal, bclk_signal, nsync_signal;

    /***************************************************************************
     * assignments
     ***************************************************************************
     */
    assign leds = led_reg;
    assign pwm_diff_p = pwm_signal;
    assign pwm_diff_n = ~pwm_signal;
    assign pwm_pin = pwm_signal;

//    assign sdata = sdata_signal;
    assign bclk = bclk_signal;
    assign nsync = nsync_signal;

    // fake testing signals
//    assign fake_pwm = pwm_signal;//read_sample;
//    assign fake_sdata = sdata_signal;//read_sample;
//    assign fake_bclk = bclk_signal;//rx_valid_si;
//    assign fake_nsync = nsync_signal;//nsync_signal;

    /***************************************************************************
     * module instances
     ***************************************************************************
     */
    /* pll */
    // pll system_clk(
    pll system_clk(
        .clock_in   (hwclk),
        .clock_out  (clk),
        .locked     (aux)
    );

    /* FT245 wrapper
     * Interface between FT245 FIFO and SIMPLE INTERFACE
     */
    ft245_block ft245_wrapper (
        .clk        (clk),
        .rst        (rst),
        // FT245 interface
        .in_out_245 (in_out_245),
        .rxf_245    (rxf_245),
        .rx_245     (rx_245),
        .txe_245    (txe_245),
        .wr_245     (wr_245),
        // simple interface - RX
        .rx_data_si (rx_data_si),
        .rx_valid_si(rx_valid_si),
        .rx_ready_si(!fifo_full),
        // simple interface - TX
        .tx_data_si (),
        .tx_valid_si(),
        .tx_ready_si()
    );

    fifo #(
        .DEPTH_WIDTH    (8),
        .DATA_WIDTH     (8)
    ) data_fifo (
        .clk        (clk),
        .rst        (rst),
        /* write port */
        .wr_data_i  (rx_data_si),
        .wr_en_i    (rx_valid_si & !fifo_full),
        /* read port */
        .rd_data_o  (sample),
        .rd_en_i    (read_sample),
        /* control signal */
        .full_o     (fifo_full),
        .empty_o    (fifo_empty)
        );


    blinky blink(
        .clk  (clk),
        .led  (led_reg[4])
    );
//    modulator #(
//        .PARAMETER01    (`PARAMETER01),
//        .PARAMETER02    (`PARAMETER02),
//        .PARAMETER03    (`PARAMETER03),
//        .PARAMETER04    (`PARAMETER04)
 //       /*  AM_CLKS_PER_PWM_STEP    1
//         *  AM_PWM_STEP_PER_SAMPLE  255
//         *  AM_BITS_PER_SAMPLE      8
//         *  AM_REPEATED_SAMPLE      30
//         */
//
//        /*  PSK_CLKS_PER_BIT        4
 //        *  PSK_BITS_PER_SYMBOL     4
//         *
//         *  PSK_REPEATED_SAMPLE     30
//         */
//
//        /*  PAM_CLKS_SAMPLING_FREQ  1200
//         *  PAM_CLKS_PER_BCLK       12
//         *  PAM_DATA_LENGHT         24
//         *  
//         */
//    ) top_modulator (
//        .clk    (clk),
//        .rst    (rst),
 //       .enable (1'b1),
 //       /* FIFO interface */
 //       .sample (sample),
  //      .empty  (fifo_empty),
  //      .read   (read_sample),
  //      /* data flow */
  //      .pwm    (pwm_signal),
 //       .sdata  (sdata_signal),
 //       .bclk   (bclk_signal),
  //      .nsync  (nsync_signal),
//
//        /* test */
 //       .symb_clk(symb_clk)
 //   );

    /**
     * We are using the leds to let the user know the current
     * transmitter status
     *
     * led_reg[0]   fifo_empty status
     * led_reg[7:5] MODULATION
     * where MODULATION is
     *  001 1 AM
     *  010 2 PAM
     *  011 3 BPSK
     *  100 4 QPSK
     *  101 5 8PSK
     */
    assign led_reg[6] = fifo_empty;
    assign led_reg[2:0] = `MODULATION;

    /* Led keep alive */
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            led_reg[7] = 0;
            count = 28'd0;
        end else if (count == 28'd120000000) begin
            if (led_reg[7] == 1'b1) begin
                led_reg[7] = 0;
            end else begin
                led_reg[7] = 1;
            end
            count = 28'd0;
        end else begin
            count = count + 1;
        end
    end

endmodule

