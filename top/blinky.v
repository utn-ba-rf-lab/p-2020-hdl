module blinky( 
    input hwclk,
    input reset_btn,
    output led0,
    output led1);

    parameter c_bit_counter = 25;
    
    reg [c_bit_counter:0] s_counter_reg;
    reg [c_bit_counter:0] s_counter_reg2;
    reg [2:0] s_counter_12 = 2;

    reg pllclk;
    reg rled0;
    reg rled1;
    wire clk12;

    assign rled0 = led0;
    assign rled1 = led1;

    pll pll(
        .clock_in(hwclk),
        .clock_out(pllclk)
    );

    // Main counter Reg
    always @ (negedge hwclk) begin
        
        if(s_counter_reg >= 10_000_000) begin
            rled0 <= ~rled0;
            s_counter_reg <= 0;
        end
        
        else begin
            s_counter_reg <= s_counter_reg+1;
        end
    end

    always @ (posedge pllclk) begin
        
        s_counter_12 <= s_counter_12 -1;

        if(s_counter_12 == 0) begin
            s_counter_12 <= 2;
            clk12 = ~clk12;
        end;
    end

    always @ (posedge clk12) begin
        if(s_counter_reg2 >= 10_000_000) begin
            rled1 <= ~rled1;
            s_counter_reg2 <= 0;
        end

        else begin
            s_counter_reg2 <= s_counter_reg2+1;
        end
    end

    //assign s_counter_next = s_counter_reg + 1;
    //assign led0 = (s_counter_reg >= {{1'b0}, {(c_bit_counter-1){1'b1}}} ) ? 1'b1 : 1'b0;
endmodule
