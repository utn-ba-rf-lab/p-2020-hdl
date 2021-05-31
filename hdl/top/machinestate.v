`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/31/2021 02:55:02 PM
// Design Name: 
// Module Name: machinestate
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module machinestate(
    input wire clk,
    input wire rst,
    input wire rx_data,
    input wire rx_ena,
    input wire tx_ena,
    output wire tx_data
    );
    
    localparam [1:0]    s0 = 2'b00,
                        s1 = 2'b01;
                        //s2 = 2'b10;
    
    // signal declaration
    reg [1:0] state_reg, state_next;
    
    // state register
    always @(posedge clk, posedge rst)
    begin
        if (rst)
            state_reg <= s0; 
        else 
            state_reg <= state_next;
    end
    
    // next state logic  
    always @(*)
    begin
        case(state_reg)
            
            // Esperando 0xAA
            s0: 
                if(rx_data == 8'h55)
                        state_next = s1;
            s1:
                state_next = s0;
            //s2:
            
        endcase
    
    end
   
   // Moore output logic
   assign tx_data = ( state_reg == s1) ? 8'hAA : 8'h00;
   assign tx_ena = ( state_reg == s1) ? 1'b1 : 1'b0;
endmodule
