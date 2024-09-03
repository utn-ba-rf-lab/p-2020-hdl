// En este modulo se va a realizar la configuracion inicial de la comunicacion
// Se hace un "handshake" inicial donde la PC (por gnuradio) envia "UTN"
// la placa contesta "UTNv2"
// luego la PC envia la velocidad de las muestras a usar (8kSps, 16kSps, 32, etc...)
// la placa contesta confirmando o rechazando la comunicacion segun si el valor enviado es valido

module init_module (
	input clk,
	input rst,
	input rx_rq,
	input rx_st,
	input tx_rq,
	input tx_st,
	input [7:0] dato_rx,
	output [2:0] tiempo_sel,
	output [15:0] samp_rate,

	output init_rdy,
);
	
	// ASCII Characters
	localparam E_ASCII = 8'd69;
	localparam K_ASCII = 8'd75;
	localparam N_ASCII = 8'd78;
	localparam O_ASCII = 8'd79;
	localparam R_ASCII = 8'd82;
	localparam T_ASCII = 8'd84;
	localparam U_ASCII = 8'd85;
	localparam v_ASCII = 8'd118;
	localparam 2_ASCII = 8'd50;

	// Samp Rates
	localparam SAMP_RATE_8K  = 16'd8000;
	localparam SAMP_RATE_11K = 16'd11025; // 11.025k
	localparam SAMP_RATE_16K = 16'd16000;
	localparam SAMP_RATE_22K = 16'd22050; // 22.05k
	localparam SAMP_RATE_24K = 16'd24000;
	localparam SAMP_RATE_32K = 16'd32000;
	localparam SAMP_RATE_44K = 16'd44100; // 44.1k
	localparam SAMP_RATE_48K = 16'd48000;
	localparam SAMP_RATE_0K  = 16'd0;

	// FSM STATES
	localparam ST_0  = 5'b0;
	localparam ST_1  = 5'b1;
	localparam ST_2  = 5'b2;
	localparam ST_3  = 5'b3;
	localparam ST_4  = 5'b4;
	localparam ST_5  = 5'b5;
	localparam ST_6  = 5'b6;
	localparam ST_7  = 5'b7;
	localparam ST_8  = 5'b8;
	localparam ST_9  = 5'b9;
	localparam ST_10 = 5'b10;
	localparam ST_11 = 5'b11;
	localparam ST_12 = 5'b12;
	localparam ST_13 = 5'b13;
	localparam ST_14 = 5'b14;
	localparam ST_15 = 5'b15;
	localparam ST_16 = 5'b16;
	localparam ST_17 = 5'b17;
	localparam ST_18 = 5'b18;
	localparam ST_19 = 5'b19;
	localparam ST_20 = 5'b20;

	// Registers    
    reg rx_rq_reg;
    reg rx_st = 1'b0;
    reg tx_st_reg;
    reg tx_rq = 1'b0;
    
	reg [7:0] dato_rx;
	reg [7:0] dato_rx_reg;
	reg [7:0] dato_tx_reg;

    reg [2:0]  tiempo_sel = 3'd0;	// Tasa de muestra seleccionada
    reg [15:0] samp_rate  = 16'd0;	// samp_rate recibido de gr-serializer

	reg [0:4] estado = ST_0;

	always @ (posedge clk) begin
		
		rx_rq_reg  <= rx_rq;
		tx_st_reg  <= tx_st;

        // Si hubo reset vamos a estado = 0
        if (rst) begin
			estado 		 = ST_0;
            rx_st 		<= 1'b0;
            tx_rq 		<= 1'b0;
            tiempo_sel  <= 3'd0;
        end

		else begin
			case (estado)

				// Espero recibir U
				ST_0: begin
					if(rx_rq_reg && !rx_st) begin
						dato_rx_reg <= dato_rx;
						rx_st <= 1'b1;
					end

					else if (!rx_rq_reg && rx_st) begin
						rx_st <= 1'b0;
						tiempo_sel <= 3'd0;
						estado = (dato_rx_reg == U_ASCII) ? ST_1 : ST_0;
					end
				end

				// Espero recibir T
				ST_1: begin
					if(rx_rq_reg && !rx_st) begin
						dato_rx_reg <= dato_rx;
						rx_st <= 1'b1;
					end
					
					else if(!rx_rq_reg && rx_st) begin
						rx_st <= 1'b0;
						estado = (dato_rx_reg == T_ASCII) ? ST_2 : ST_0;
					end
				end
				
				// Espero recibir N
				ST_2: begin
					if(rx_rq_reg && !rx_st) begin
						dato_rx_reg <= dato_rx;
						rx_st <= 1'b1;
					end
					
					else if(!rx_rq_reg && rx_st) begin
						rx_st <= 1' b0;
						estado = (dato_rx_reg == N_ASCII) ? ST_3 : ST_0;
					end
				end
				
				// Envio U
				ST_3: begin
					if(!tx_st_reg && !tx_rq) begin
						dato_tx_reg <= U_ASCII;
						tx_rq <= 1'b1;
					end
					
					else if(tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_4;
					end
				end
				
				// Envio T
				ST_4: begin

					if(!tx_st_reg && !tx_rq) begin
						dato_tx_reg <= T_ASCII;
						tx_rq <= 1'b1;
					end
					
					else if(tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_5;
					end
				end

				// Envio N
				ST_5: begin
					
					if(!tx_st_reg && !tx_rq) begin
						dato_tx_reg <= N_ASCII;
						tx_rq <= 1'b1;
					end
					
					else if(tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_6;
					end
				end

				// Envio v
				ST_6: begin

					if(!tx_st_reg && !tx_rq) begin
						dato_tx_reg <= v_ASCII;
						tx_rq <= 1'b1;
					end
					
					else if(tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_7;
					end
				end

				// Envio 2
				ST_7: begin

					if(!tx_st_reg && !tx_rq) begin
						dato_tx_reg <= 2_ASCII;
						tx_rq <= 1'b1;
					end
					
					else if(tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_8;
					end
				end

				// Envio \n
				ST_8: begin
					
					if(!tx_st_reg && !tx_rq) begin
						dato_tx_reg <= 8'd10;
						tx_rq <= 1'b1;
					end
					
					else if(tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_9;
					end
				end

				// Recibo parte baja del samp rate
				ST_9: begin
					
					if(rx_rq_reg && !rx_st) begin
						dato_rx_reg <= dato_rx;
						rx_st <= 1'b1;
					end
					
					else if(!rx_rq_reg && rx_st) begin
						rx_st <= 1'b0;
						samp_rate[7:0] <= dato_rx_reg;
						estado = ST_10;
					end
				end

				// Recibo parte alta del samp rate
				ST_10: begin
					
					if(rx_rq_reg && !rx_st) begin
						dato_rx_reg <= dato_rx;
						rx_st <= 1'b1;
					end
					
					else if(!rx_rq_reg && rx_st) begin
						rx_st <= 1'b0;
						samp_rate[15:8] <= dato_rx_reg;
						estado = ST_11;
					end
				end

				// Chequeo que el samp_rate sea valido
				ST_11: begin
					estado = ST_12;

					case(samp_rate)
						
						SAMP_RATE_8K : tiempo_sel <= 3'd0;

						SAMP_RATE_11K: tiempo_sel <= 3'd1;
						
						SAMP_RATE_16K: tiempo_sel <= 3'd2;
						
						SAMP_RATE_22K: tiempo_sel <= 3'd3;
						
						SAMP_RATE_24K: tiempo_sel <= 3'd4;

						SAMP_RATE_32K: tiempo_sel <= 3'd5;

						SAMP_RATE_44K: tiempo_sel <= 3'd6;

						SAMP_RATE_48K: tiempo_sel <= 3'd7;

						//SAMP_RATE_0K: Modo best efforts (tiempo_sel no importa)

						default: estado = ST_15; // samp_rate inválido, informo ERROR
					endcase
				end

				// Envio O
				ST_12: begin

					if(!tx_st_reg && !tx_rq) begin
            			dato_tx_reg <= O_ASCII;
            			tx_rq <= 1'b1;
        			end

					else if(tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_13;
					end
				end

				// Envio K
				ST_13: begin

					if(!tx_st_reg && !tx_rq) begin
            			dato_tx_reg <= K_ASCII;
            			tx_rq <= 1'b1;
        			end

					else if(tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_14;
					end
				end

				// Envio \n y senalizo inicializacion correcta
				ST_14: begin

					if(!tx_st_reg && !tx_rq) begin
            			dato_tx_reg <= 8'd10;
            			tx_rq <= 1'b1;
        			end

					else if(tx_st_reg && tx_rq) begin
						tx_rq 	<= 1'b0;
						init_rdy <= 2'b1;
						estado = ST_0;
					end
				end

				// Envio E
        		ST_15: begin
					if (!tx_st_reg && !tx_rq) begin
            			dato_tx_reg <= E_ASCII;
            			tx_rq <= 1'b1;
					end

					else if (tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_16;
					end
       			end

				// Envio R
				ST_16: begin
					if (!tx_st_reg && !tx_rq) begin
						dato_tx_reg <= R_ASCII;
						tx_rq <= 1'b1;
					end

					else if (tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_17;
					end
				end
				
				// Envio R
				ST_17: begin
					if(!tx_st_reg && !tx_rq) begin
						dato_tx_reg <= R_ASCII;
						tx_rq <= 1'b1;
					end

					else if(tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_18;
					end
				end

				// Envio O
				ST_18: begin
					if(!tx_st_reg && !tx_rq) begin
						dato_tx_reg <= O_ASCII;
						tx_rq <= 1'b1;
					end

					else if(tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_19;
					end
				end

				// Envio R
				ST_19: begin
					if(!tx_st_reg && !tx_rq) begin
						dato_tx_reg <= R_ASCII;
						tx_rq <= 1'b1;
					end

					else if(x_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						estado = ST_20; 
					end
				end

				// Envio \n y senalizo error
				ST_20: begin
					if(!tx_st_reg && !tx_rq) begin
						dato_tx_reg <= 8'd10;
						tx_rq <= 1'b1;
					end

					else if(tx_st_reg && tx_rq) begin
						tx_rq <= 1'b0;
						init_rdy <= 2'd2;
						estado = ST_0; 
					end	
				end
			endcase
		end
	end
endmodule