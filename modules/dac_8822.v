// Modulo para el DAC8822
// Se busca implementar el control para dicho DAC.

/* --------------- Resumen --------------- */

// |--------- Address pins ----------|
// |=================================|
// | DAC_A1 | DAC_A0 | OUTPUT UPDATE |
// |========|========|============== |
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

module top_module (
	input [15:0] dac_in,
	output dac_rs,
	output dac_rstsel,
	output dac_ldac,
	output dac_a0,
	output dac_a1,
	output dac_wr,
);

endmodule