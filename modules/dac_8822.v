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
// 	- 1. Llega dato de parte real. Se direcciona (A0 y A1) al canal deseado y se carga el in_register.
//	- 2. Llega dato de parte img. Se direcciona y se carga el in_register del otro canal.
//	- 3. Direccionamos a ambos canales y cargamos los dac_registers a partir de los in_registers.

module dac_8822 (
    input  clk,
    input  reset,
        
    input  [31:0] data, // Dato complejo a transmitir a la PC desde Mercurial
    input  dac_rq,      // Alto para indicar que hay un dato desde Mercurial a transmitir
    output dac_st      // Flanco positivo cuando el dato fue leído por este módulo
);
    

    /*output [15:0] dac_8822_data,
    output [1:0] dac_addr,
    output not_dac_rs,
    output not_dac_wr,
    output dac_ldac*/



	//input data_rdy,
	//input rst,
	//output dac_rstsel,

	/* ----- params ----- */
	localparam ST_IDLE = 0;
	localparam ST_REAL = 1;
	localparam ST_IMG  = 2;
	localparam ST_SEND = 3;

	/* ----- registers ----- */
	reg [0:1] next_state = ST0;
	reg [0:1] current_state = ST0; 
	
	always @ (posedge clk) begin

		//current_state <= next_state;

		//// reset del sistema
		//if(rst) begin
			//// TODO: Ver que mas hay que hacer en el reset.
			//current_state <= ST_IDLE;
			//next_state_state <= ST_IDLE;
		//end

		//else begin

			//case (current_state)
				
				//ST_IDLE: begin
					//if(data_rdy) begin
						
					//end
				//end
				
				//ST_REAL: begin
				//end
				
				//ST_IMG: begin
				//end
				
				//ST_SEND: begin
				//end 

				//default: 
			//endcase
		//end
	end

endmodule 
