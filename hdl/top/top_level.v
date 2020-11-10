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
    output  wr_245
);
/***************************************************************************
                                    signals
***************************************************************************/
    reg clk;
    reg [7:0] led_reg;

    //RS232
    wire RxD_data_ready;
    wire [7:0] RxD_data;
    wire RxD_idle;
    wire RxD_endofpacket;
/***************************************************************************
                                    assignments
***************************************************************************/
    assign leds = led_reg;


/***************************************************************************
                                     module instances
***************************************************************************/
    
    /* pll */
    pll system_clk(
        .clock_in   (hwclk),        // 12 mhz
        .clock_out  (clk),          // 120 mhz
        .locked     (aux)
    );

       
    blinky blink(
        .clk  (clk),
        .led  (led_reg[4])
    );

    async_receiver receive232(
        .clk            (clk),
        .RxD            (in_out_245[0]),    //en realidad es RS232_Rx_TTL pero los chicos lo cambiaron
        .RxD_data_ready (RxD_data_ready),
        .RxD_data       (RxD_data),
        .RxD_idle       (RxD_idle),
        .RxD_endofpacket(RxD_endofpacket)
    );
    always @(posedge clk) 
    begin
        if (RxD_data_ready == 1) begin
            if (RxD_data == 8'b11111111) begin
                led_reg[1] = 1;
            end
            else if (RxD_data == 8'b00000000) begin
                led_reg[1] = 0;
            end
        end
    end
 

endmodule
