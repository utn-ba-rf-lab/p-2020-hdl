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
    output dac_rstsel
);

	/* ----- params ----- */
	localparam ST_IDLE = 1; // espero a que me avisen que hay un dato para mandar al dac 
	localparam ST_REAL = 2; // cargamos 
	localparam ST_IMG  = 3;
	localparam ST_SEND = 4;

	/* ----- registers ----- */
	reg [2:0]  next_state    = 3'd1;
	reg [2:0]  current_state = 3'd1;
	reg [15:0] data_real, data_imag;
	reg [1:0]  counter = 2'd0;

	assign dac_rstsel = 1'b0; // para que el nuevo dac siempre se resetee a 0 en la salida.

	assign data_real = data[31:16];
	assign data_imag = data[15:0];

	always @ (posedge clk) begin
		
		current_state <= next_state;
		
		// dac_8822_data <= 16'b0;
		// dac_addr <= 2'b1;  // no le apunta a nada
		// dac_ldac <= 1'b0;
		// dac_wr_neg <= 1'b1;
		dac_rstsel <= 1'b0;

		// reset del sistema
		if(reset) begin
			current_state <= 3'd1;
			next_state <= 3'd1;
			dac_rs_neg <= 1'b0;
		end

		else begin
			case (current_state)
				
				3'd1: begin
					dac_wr_neg <= 1'b1;
					dac_ldac   <= 1'b0;
					dac_rs_neg <= 1'b1;
					if(dac_rq) begin
						dac_addr   <= 2'b0; // voy a escribir al canal A.
						dac_st     <= 1'b1;
						counter    <= 2'd0;
						next_state <= 3'd2;
					end
				end
				
				3'd2: begin
					
					dac_wr_neg    <= 1'b0;
					dac_8822_data <= 16'hB000; // data_real;
					counter++;
					
					if (counter==2'd3) begin
						dac_wr_neg <= 1'b1;
						// dac_addr   <= 2'b11; // voy a escribir al canal B.
						counter    <= 2'd0;
						next_state <= 3'd4; // Antes ST_IMG
					end
				end
				
// 				ST_IMG: begin
// 					
// 					dac_wr_neg    <= 1'b0;
// 					dac_8822_data <= data_imag;
// 					counter++;
// 					
// 					if (counter==2'd3) begin
// 						dac_wr_neg <= 1'b1;
// 						dac_addr   <= 2'b10; // voy a escribir al canal B.
// 						counter    <= 2'd0;
// 						next_state <= ST_SEND;
// 					end
// 				end
				
				3'd4: begin
					dac_ldac   <= 1'b1;
					counter++;
					if(counter==2'd3) begin
						dac_ldac <= 1'b0;
						counter    <= 2'd0;
						dac_st <= 1'b0;
						next_state <= 3'd1;
					end
				end

				default: next_state <= 3'd1;
			endcase
		end
	end
endmodule
