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
// Al ser partes de un mismo dato tienen que aparecer a la salida simultaneamente.
// Como tiene que funcionar:
// 	- 1. Llega dato de parte real. Se direcciona (con A0 y A1) al canal deseado y se carga el in_register.
//	- 2. Llega dato de parte img. Se direcciona y se carga el in_register del otro canal.
//	- 3. Direccionamos a ambos canales y cargamos los dac_registers a partir de los in_registers.

module dac_8822 (
	input  clk,
	input  rst,
	input  data_valid; // avisa a este modulo si hay algun dato
	output data_ready; // listo para leer/recibir un dato
	input  [15:0] data_in;

	// dac pins
	output [15:0] dac_data, // dato enviado al dac (TODO: ver tema si resulta confuso el nombre)
	output dac_rs,
	output dac_rstsel,
	output dac_ldac,
	output dac_a0,
	output dac_a1,
	output dac_wr, 
);

	/* ----- params ----- */
	localparam ST_IDLE 	  = 0;
	localparam ST_ADDRESS = 1;
	localparam ST_IN_REG  = 2;
	localparam ST_DAC_REG = 3;

	/* ----- registers ----- */
	reg [0:1]	state = ST0;
	reg [0:15]	data_reg;
	reg data_valid_reg; 
	
	/* ----- registers ----- */
	assign dac_data = data_reg;

	always @ (posedge clk) begin

		data_valid_reg <= data_valid;

		// reset del sistema
		if(rst) begin
			// TODO: Ver que mas hay que hacer en el reset.
			current_state <= ST_IDLE;
			next_state_state <= ST_IDLE;
			data_ready <= 1'b1;
			data_reg <= 16'd0;
		end

		else begin

			case (current_state)
				
				ST_IDLE: begin
					dac_rs	 <= 1'b1;
					dac_wr	 <= 1'b1;
					dac_ldac <= 1'b0; 
					// si hay un dato disponible y puedo leer
					if(data_valid_reg && data_ready_reg) begin
						data_reg <= data_in;
						data_ready <= 1'b0;
						estado <= ST_ADDRESS;
					end
				end
				
				// direcciono a ambos canales en este caso
				ST_ADDRESS: begin
					dac_a1 <= 1'b1;
					dac_a0 <= 1'b0;
					estado <= ST_IN_REG;
				end
				
				// cargo los in_registers
				ST_IN_REG: begin
					dac_rs	 <= 1'b1;
					dac_wr	 <= 1'b0;
					dac_ldac <= 1'b0;
					estado <= ST_DAC_REG;
				end
				
				// cargo los dac_registers desde los in_registers
				ST_DAC_REG: begin
					dac_rs	 <= 1'b1;
					dac_wr	 <= 1'b1;
					dac_ldac <= 1'b1;
					data_ready <= 1'b1; // TODO: ver si hay que hacer otro estado
					estado <= ST_IDLE; 
				end 

				default:
					estado <= ST_IDLE; 
			endcase
		end
	end

endmodule