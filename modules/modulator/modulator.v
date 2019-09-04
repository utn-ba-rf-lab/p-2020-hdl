`include "project_defines.v"

module modulator #(
    parameter FOO = 10,
    parameter AM_CLKS_IN_PWM_STEPS = `AM_PWM_STEPS,
    parameter AM_PWM_STEPS = `AM_PWM_STEPS,
)(
    input clk,
    input rst,
    output pwm
);
    localparam WIDTH = $clog2(FOO);

    /* registers */
    reg [WIDTH-1:0] count;
    reg tc_pwm_step, tc_pwm_symb;
    reg [AM_PWM_STEPS-1:0] shift_register;


    /******** testing signals ********/
    reg [100-1:0] sine_10k;
    reg [6:0] counter_sine_10k;
    /******** testing signals ********/


    // counter to generate ticks at pwm-steps frequency
    counter #(
        .MODULE  (AM_CLKS_IN_PWM_STEPS),
    ) inst_counter_pwm_steps (
        .clk    (clk),
        .rst    (rst),
        .enable (1'b1),
        .tc     (tc_pwm_step)
    );

    // counter to generate ticks at pwm-symbols frequency
    counter #(
        .MODULE  (AM_PWM_STEPS),
    ) inst_counter_pwm_symb (
        .clk    (clk),
        .rst    (rst),
        .enable (tc_pwm_step),
        .tc     (tc_pwm_symb)
    );

    // shift register to serialize each pwm-symbol
    always @ (posedge clk) begin
        if(rst == 1'b1)
            shift_register <= AM_PWM_STEPS'd0;
        else if (tc_pwm_symb == 1'b1) begin
            counter_sine_10k <= counter_sine_10k + 1;
            case(counter_sine_10k)
                // 0 - 10
                7'd0:   shift_register <= 64'd0;
                7'd1:   shift_register <= 64'd0;
                7'd2:   shift_register <= 64'd0;
                7'd3:   shift_register <= 64'd0;
                7'd4:   shift_register <= 64'd0;

                7'd5:   shift_register <= 64'd0;
                7'd6:   shift_register <= 64'd0;
                7'd7:   shift_register <= 64'd0;
                7'd8:   shift_register <= 64'd0;
                7'd9:   shift_register <= 64'd0;
                // 10 - 20
                7'd10:   shift_register <= 64'd0;
                7'd11:   shift_register <= 64'd0;
                7'd12:   shift_register <= 64'd0;
                7'd13:   shift_register <= 64'd0;
                7'd14:   shift_register <= 64'd0;

                7'd15:   shift_register <= 64'd0;
                7'd16:   shift_register <= 64'd0;
                7'd17:   shift_register <= 64'd0;
                7'd18:   shift_register <= 64'd0;
                7'd19:   shift_register <= 64'd0;
                // 20 - 30
                7'd20:   shift_register <= 64'd0;
                7'd21:   shift_register <= 64'd0;
                7'd22:   shift_register <= 64'd0;
                7'd23:   shift_register <= 64'd0;
                7'd24:   shift_register <= 64'd0;

                7'd25:   shift_register <= 64'd0;
                7'd26:   shift_register <= 64'd0;
                7'd27:   shift_register <= 64'd0;
                7'd28:   shift_register <= 64'd0;
                7'd29:   shift_register <= 64'd0;
                // 30 - 40
                7'd30:   shift_register <= 64'd0;
                7'd31:   shift_register <= 64'd0;
                7'd32:   shift_register <= 64'd0;
                7'd33:   shift_register <= 64'd0;
                7'd34:   shift_register <= 64'd0;

                7'd35:   shift_register <= 64'd0;
                7'd36:   shift_register <= 64'd0;
                7'd37:   shift_register <= 64'd0;
                7'd38:   shift_register <= 64'd0;
                7'd39:   shift_register <= 64'd0;
                // 40 - 50
                7'd40:   shift_register <= 64'd0;
                7'd41:   shift_register <= 64'd0;
                7'd42:   shift_register <= 64'd0;
                7'd43:   shift_register <= 64'd0;
                7'd44:   shift_register <= 64'd0;

                7'd45:   shift_register <= 64'd0;
                7'd46:   shift_register <= 64'd0;
                7'd47:   shift_register <= 64'd0;
                7'd48:   shift_register <= 64'd0;
                7'd49:   shift_register <= 64'd0;
                // 50 - 60
                7'd50:   shift_register <= 64'd0;
                7'd51:   shift_register <= 64'd0;
                7'd52:   shift_register <= 64'd0;
                7'd53:   shift_register <= 64'd0;
                7'd54:   shift_register <= 64'd0;

                7'd55:   shift_register <= 64'd0;
                7'd56:   shift_register <= 64'd0;
                7'd57:   shift_register <= 64'd0;
                7'd58:   shift_register <= 64'd0;
                7'd59:   shift_register <= 64'd0;
                // 60 - 70
                7'd60:   shift_register <= 64'd0;
                7'd61:   shift_register <= 64'd0;
                7'd62:   shift_register <= 64'd0;
                7'd63:   shift_register <= 64'd0;
                7'd64:   shift_register <= 64'd0;

                7'd65:   shift_register <= 64'd0;
                7'd66:   shift_register <= 64'd0;
                7'd67:   shift_register <= 64'd0;
                7'd68:   shift_register <= 64'd0;
                7'd69:   shift_register <= 64'd0;
                // 70 - 80
                7'd70:   shift_register <= 64'd0;
                7'd71:   shift_register <= 64'd0;
                7'd72:   shift_register <= 64'd0;
                7'd73:   shift_register <= 64'd0;
                7'd74:   shift_register <= 64'd0;

                7'd75:   shift_register <= 64'd0;
                7'd76:   shift_register <= 64'd0;
                7'd77:   shift_register <= 64'd0;
                7'd78:   shift_register <= 64'd0;
                7'd79:   shift_register <= 64'd0;
                // 80 - 90
                7'd80:   shift_register <= 64'd0;
                7'd81:   shift_register <= 64'd0;
                7'd82:   shift_register <= 64'd0;
                7'd83:   shift_register <= 64'd0;
                7'd84:   shift_register <= 64'd0;

                7'd85:   shift_register <= 64'd0;
                7'd86:   shift_register <= 64'd0;
                7'd87:   shift_register <= 64'd0;
                7'd88:   shift_register <= 64'd0;
                7'd89:   shift_register <= 64'd0;
                // 90 - 100
                7'd90:   shift_register <= 64'd0;
                7'd91:   shift_register <= 64'd0;
                7'd92:   shift_register <= 64'd0;
                7'd93:   shift_register <= 64'd0;
                7'd94:   shift_register <= 64'd0;

                7'd95:   shift_register <= 64'd0;
                7'd96:   shift_register <= 64'd0;
                7'd97:   shift_register <= 64'd0;
                7'd98:   shift_register <= 64'd0;
                7'd99:   shift_register <= 64'd0;

                default:
                    shift_register <= 64'd0;                    
            endcase
        end else if (tc_pwm_step == 1'b1)
            shift_register <= {shift_register[AM_PWM_STEPS-2:0],shift_register[AM_PWM_STEPS-1]};
    end

    // output assignment
    assign pwm = shift_register[AM_PWM_STEPS-1];

endmodule
