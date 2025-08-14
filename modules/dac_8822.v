// Modulo para el DAC8822
// Se busca implementar el control para dicho DAC
// para trabajar con senales IQ.

/* --------------- Resumen --------------- */

// |--------- Address pins ----------|
// |=================================|
// | DAC_A1 | DAC_A0 | OUTPUT UPDATE |
// |========|========|===============|
// |   0    |   0    |     DAC A     |
// |   0    |   1    |     None      |
// |   1    |   0    |  DAC A and B  |
// |   1    |   1    |     DAC B     |

// | ------------- Function of control inputs --------------- |
// |==========================================================|
// |  ~RS   |  ~WR   |  LDAC  |       REGISTER OPERATION      |
// |========|========|========|===============================|
// |   0    |   X    |   X    |            RESET              |
// |   1    |   0    |   0    |   load in_reg with 16 bits    |
// |   1    |   1    |   1    |   load dac_reg with in_reg	  |
// |   1    |   0    |   1    |  in and dac reg transparent   |
// |   1    | low(?) | low(?) |              -                |
// |   1    |   1    |   0    |            NO OP			  |

// Cada dato es un numero complejo con su parte real e img de 16 bits c/u.
// Al ser partes de un mismo dato tienen que aparecer a la salida (del dac) simultaneamente.
// Como tiene que funcionar:
// 	- 1. Llega dato de parte real e img. 
//  - 2. Se direcciona (A0 y A1) al canal real y se carga el in_register del mismo.
//	- 2. Se direcciona al canal imaginario y se carga el in_register del canal.
//	- 3. Direccionamos a ambos canales y cargamos los dac_registers a partir de los in_registers.

module dac_8822 (
    input  clk,
    input  reset,
// Descomentado
    input  [31:0] data, // Dato complejo a transmitir a la PC desde Mercurial
    input  dac_rq,      // Alto para indicar que hay un dato desde Mercurial a transmitir
    output dac_st,      // Flanco positivo cuando el dato fue leído por este módulo

    output [15:0] dac_8822_data, // Word que va al DAC 8822, físico.
    output [1:0]  dac_addr,

// Descomentado
    output dac_rs_neg,

    output dac_wr_neg,
    output dac_ldac,
    output dac_rstsel,
    
    output dac_fake_led1
);

	/* ----- params ----- */
	localparam ST_IDLE = 1; // espero a que me avisen que hay un dato para mandar al dac 
	localparam ST_REAL = 2; // cargamos 
	localparam ST_IMG  = 3;
	localparam ST_SEND = 4;

	/* ----- registers ----- */
	reg [3:0]  next_state    = 4'd1;
	reg [3:0]  current_state = 4'd1;
	reg [15:0] data_real, data_imag;
	reg [1:0]  counter = 2'd0;
	reg dac_rq_reg;                             // Vale uno cuando recibe un pedido de conversión
	reg reset_reg;



	assign dac_rstsel = 1'b0; // para que el nuevo dac siempre se resetee a 0 en la salida.
//	assign dac_ldac = 1'b1;
	assign data_real = data[15:0];
	assign data_imag = data[15:0];

	always @ (posedge clk) begin
		
		current_state <= next_state;
		dac_rq_reg <= dac_rq;
		reset_reg <= reset;
		dac_ldac <= 1'b0;


		// dac_8822_data <= 16'b0;
		// dac_addr <= 2'b1;  // no le apunta a nada
		// dac_ldac <= 1'b0;
		// dac_wr_neg <= 1'b1;
		// dac_rstsel <= 1'b0;

		// reset del sistema
		if(reset_reg) begin
			current_state <= 3'd1;
			next_state <= 3'd1;
			dac_rs_neg <= 1'b0;
			current_state <= 4'd1;
			next_state <= 4'd1;
			// dac_rs_neg <= 1'b0;
			dac_fake_led1 <= 0;
		end

		else begin
			case (current_state)
				
				4'd1: begin
					dac_wr_neg <= 1'b1;
					dac_rs_neg <= 1'b1;
					if(dac_rq_reg) begin
						next_state <= 4'd2;
						dac_st     <= 1'b1;
					end
				end
				
				4'd2: begin
					dac_8822_data <= data_real + 16'd1639;
					dac_addr   <= 2'b00;
					next_state <= 4'd3;
				end

				4'd3: begin
					dac_wr_neg <= 1'b0;
					next_state <= 4'd4;
				end

				4'd4: begin
					dac_wr_neg <= 1'b1;
					//dac_st <= 1'b0;
					
					next_state <= 4'd5;

				end

				// Escritura de canal B

				4'd5: begin
					dac_wr_neg <= 1'b1;

					//if(dac_rq_reg) begin
						next_state <= 4'd6;
						//dac_st     <= 1'b1;
					//end
				end
				
				4'd6: begin
					dac_8822_data <= data_imag;
					dac_addr   <= 2'b11;
					next_state <= 4'd7;
				end

				4'd7: begin
					dac_wr_neg <= 1'b0;
					next_state <= 4'd8;
				end

				4'd8: begin
					dac_wr_neg <= 1'b1;
					
					next_state <= 4'd9;

				end

				4'd9: begin
					
					dac_addr   <= 2'b10;
					next_state <= 4'd10;

				end

				4'd10: begin

					dac_st <= 1'b0;
					dac_ldac <= 1'b1;

					next_state <= 4'd1;

				end



				default: next_state <= 4'd1;

			endcase
		end
	end
endmodule
