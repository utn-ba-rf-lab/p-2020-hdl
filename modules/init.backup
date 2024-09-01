// En este modulo se va a realizar la configuracion inicial de la comunicacion
// Se hace un "handshake" inicial donde la PC (por gnuradio) envia "UTN"
// la placa contesta "UTNv2"
// luego la PC envia la velocidad de las muestras a usar (8kSps, 16kSps, 32, etc...)
// la placa contesta confirmando o rechazando la comunicacion segun si el valor enviado es valido

module init_module (
	input clk,
	input rst,

	input  hwclk,        /* Clock*/
    input  reset_btn,    /* Botón de reset*/
    inout  [7:0] io_245, /* Bus de datos con el FTDI*/
    input  txe_245,
    input  rxf_245,
    
    output rx_245,
    output wr_245,
    output led0,
    output led1,
    output pin_L23B,
    output pin_L4B,

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

	// FSM STATES
	localparam ST_0 = 5'b0;
	localparam ST_0 = 5'b1;
	localparam ST_0 = 5'b2;
	localparam ST_0 = 5'b3;
	localparam ST_0 = 5'b4;
	localparam ST_0 = 5'b5;
	localparam ST_0 = 5'b6;
	localparam ST_0 = 5'b7;
	localparam ST_0 = 5'b8;
	localparam ST_0 = 5'b9;
	localparam ST_0 = 5'b10;
	localparam ST_0 = 5'b11;
	localparam ST_0 = 5'b12;
	localparam ST_0 = 5'b13;
	localparam ST_0 = 5'b14;
	localparam ST_0 = 5'b15;
	localparam ST_0 = 5'b16;
	localparam ST_0 = 5'b17;
	localparam ST_0 = 5'b18;
	localparam ST_0 = 5'b19;
	localparam ST_0 = 5'b20;
	localparam ST_0 = 5'b21;

	// Registers    
    reg rx_rq_reg;
	reg rxf_245_reg;
    reg rx_st = 1'b0;
    reg [7:0] dato_rx;
	reg [7:0] dato_rx_reg;

    reg tx_st_reg;
    reg tx_rq = 1'b0;
	reg [7:0] dato_tx_reg;

    reg alarma = 1'b1;
    reg tiempo_ant = 1'b0;
    reg medio_sg_ant = 1'b0;
    reg reset_sw = 1'b0;
    reg [7:0]  tiempos;				// 48, 44.1, 32, 24, 22.05, 16, 11.025, 8 KHz
    reg [1:0]  gracia = 2'd2;		// Cantidad de segundos antes de WatchDog operativo
    reg [2:0]  tiempo_sel = 3'd0;	// Tasa de muestra seleccionada
    reg [15:0] samp_rate = 16'd0;	// samp_rate recibido de gr-serializer
    reg [11:0] WatchDog = 12'd4000;	// Desciende por cada muestra recibida
    reg [11:0] Ctn_anim = 12'd4000;	// Desciende por cada muestra recibida y se recarga

	reg [0:4] estado = ST_0;

	always @ (posedge clk) begin
		
		rx_rq_reg  <= rx_rq;
		tx_st_reg  <= tx_st;
		
        // Si hubo reset vamos a estado = 0
        if (rst) begin
            rx_st 		<= 1'b0;
            tx_rq 		<= 1'b0;
            alarma 		<= 1'b1;
            estado 		<= ST_0;
            reset_sw	<= 1'b0;
            tiempo_sel  <= 3'd0;
        end

		else begin

			case (estado)

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

				
				ST_1: begin
				end
				
				ST_2: begin
				end
				
				ST_3: begin
				end
				
				ST_4: begin
				end

				ST_5: begin
				end

			endcase
		end
	end
endmodule