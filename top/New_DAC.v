/* new_saw_tooth.v código para probar el dac nuevo.
Genera un diente de sierra de 1 KHz a 48 KSpS sobre el dac nuevo, para ello:
1. Espera recibir "UTN" (Usar minicom -D /dev/ttyUSB1)
2. Luego envia "OK\n"
3. Pone le dac spi (anterior) en su máxima salida (384 mVolts) , pues es la referencia del dac nuevo
3. Genera el diente de sierra
4. Con botón de RESET Pone le dac spi en 0 Volts y vuelve a 1.

Significado de los leds
0 - Prende y Apaga cada un segundo
1 - Apaga si está en estado operativo (recibió "UTN", envió "OK\n" entró en régimen generando el diente de sierra) */

module top_module (

    input  hwclk,        /* Clock*/
    input  reset_btn,    /* Botón de reset*/
    inout  [7:0] io_245, /* Bus de datos con el FTDI*/
    input  txe_245,
    input  rxf_245,
    
    output rx_245,
    output wr_245,
    //output [7:0] leds,
    output led0,
    output led1,
    output fake_led1,
    output fake_led2,
    output pin_L23B,
    output pin_L4B,
    output dac_spi_data,
    output dac_spi_clk,
    output dac_spi_sync  /*SYNC del AD5061*/
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
	//localparam DOS_ASCII = 8'd50;

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
	localparam ST_0  = 5'd0;
	localparam ST_1  = 5'd1;
	localparam ST_2  = 5'd2;
	localparam ST_3  = 5'd3;
	localparam ST_4  = 5'd4;
	localparam ST_5  = 5'd5;
	localparam ST_6  = 5'd6;
	localparam ST_7  = 5'd7;
	localparam ST_8  = 5'd8;
	localparam ST_9  = 5'd9;
	localparam ST_10 = 5'd10;
	localparam ST_11 = 5'd11;
	localparam ST_12 = 5'd12;
	localparam ST_13 = 5'd13;
	localparam ST_14 = 5'd14;
	localparam ST_15 = 5'd15;
	localparam ST_16 = 5'd16;
	localparam ST_17 = 5'd17;
	localparam ST_18 = 5'd18;
	localparam ST_19 = 5'd19;
	localparam ST_20 = 5'd20;


	// `include "Param.vh"
    /* --------------- Signals --------------- */

    reg clk;
    reg [4:0]  estado = 5'b0;                    // estado indica en que estado está la placa
    reg rxf_245_reg;
    reg [7:0]  dato_rx, dato_rx_reg, dato_tx_reg;
    reg rx_rq_reg;
    reg rx_st = 1'b0;
    reg tx_rq = 1'b0;
    reg tx_st_reg;
    reg alarma = 1'b1;
    reg [15:0] muestra = 16'd0;                 // El valor que va al DAC
    reg dac_rq = 1'b0;
    reg dac_st_reg;
    reg tiempo_ant = 1'b0;
    //reg [5:0] animacion;
    reg [11:0] WatchDog = 12'd4000;             // Desciende por cada muestra recibida
    reg [11:0] Ctn_anim = 12'd4000;             // Desciende por cada muestra recibida y se recarga
    reg medio_sg_ant = 1'b0;
    reg [1:0]  gracia = 2'd2;                    // Cantidad de segundos antes de WatchDog operativo
    reg reset_sw = 1'b0;
    reg [7:0]  tiempos;                          // 48, 44.1, 32, 24, 22.05, 16, 11.025, 8 KHz
    reg [2:0]  tiempo_sel = 3'd0;                // Tasa de muestra seleccionada
    reg [15:0] samp_rate = 16'd0;               // samp_rate recibido de gr-serializer

    //reg st0 = 1'b0;
    //reg st1 = 1'b0;
    
    /* --------------- Assignments --------------- */

    assign clk = hwclk;
    assign reset_sgn = (reset_hw | reset_sw);
    assign rxf_245 = rxf_245_reg;
    //assign fake_led2 = alarma;
    assign led1 = alarma;
    //assign leds[6:1] = animacion[5:0];
    assign pin_L23B = tiempo;
    assign pin_L4B = (estado == ST_17);         // Pasa a alto si está esperando para convertir (Idle)
    assign tiempo = tiempos[tiempo_sel];
    //assign led0 = st0;
    //assign led1 = st1;

    /* --------------- Modules instances --------------- */

    temporizador temporizador(
        .clock_in   (clk),
        .reset_btn  (reset_btn),
        .medio_sg   (medio_sg),
        .rst_out    (reset_hw),
        .samp_rates (tiempos),
        .latido     (led0)
    );
    
    ftdi ftdi(
        .clock_in   (clk),
        .reset      (reset_sgn),
        .io_245     (io_245),   // Bus de datos con el FTDI
        .txe_245    (txe_245),  // Del FTDI, vale 0 si está disponible para transmitir a la PC
        .rxf_245_in (rxf_245),  // Del FTDI, vale 0 cuando llegó un dato desde la PC
        .rx_245_out (rx_245),   // Del FTDI, vale 0 para solicitar lectura de dato que llegó de la PC y lo toma en el flanco positivo
        .wr_245     (wr_245),   // Del FTDI, en el flanco descendente almacena el dato a transmitir a la PC
        .rx_data    (dato_rx),  // Dato recibido de la PC hacia Mercurial
        .rx_rq      (rx_rq),    // Alto para avisar a Mercurial que llegó un dato
        .rx_st      (rx_st),    // Flanco positivo cuando el dato fue leído por Mercurial          
        .tx_data    (dato_tx_reg),  // Dato a transmitir a la PC desde Mercurial
        .tx_rq      (tx_rq),    // Alto para indicar que hay un dato desde Mercurial a transmitir
        .tx_st      (tx_st)     // Flanco positivo cuando el dato fue leído por este módulo
    );

    dac_spi dac_spi(
        .clock_in (clk),
        .reset    (reset_sgn),
    
        .dac_data (muestra),      // Muestra a convertir
        .dac_rq   (dac_rq),       // Alto para indicar que hay una muestra para convertir
        .dac_st   (dac_st),       // Vale cero si el DAC está disponible para nueva conversión

        .sdata    (dac_spi_data),
        .bclk     (dac_spi_clk),
        .nsync    (dac_spi_sync)  // SYNC del AD5061  
    );
        
    /* always */
    /* Estados de la placa
    estado = 0 Inicio, espera "U", si no va estado 0
    estado = 1 Recibió "U" espera "T", si no va estado 0
    estado = 2 Recibió "T" espera "N" y va a estado 10, si no va estado 0
    estado = 10 y 11 Determina tiempo_sel en base a samp_rate para operar en 48 KSpS, va estado 12
    estado = 12 Envía "O"
    estado = 13 Envía "K"
    estado = 14 Envía "\n", ajusta variables de operación
    estado = 15 y 16 Operativo: Determina la muestra del diente de sierra y vá a estado 17
    estado = 17 Operativo: Espera tiempo de muestra
    estado = 18 Operativo: Ordena conversión, WatchDog, Animación, va estado 15
    estado = 19 Envía "E"
    estado = 20 Envía "R"
    estado = 21 Envía "R"
    estado = 22 Envía "O"
    estado = 23 Envía "R"
    estado = 24 Envía "\n", va estado 0
    */
    always @ (posedge clk) begin
        
        rx_rq_reg <= rx_rq;
        tx_st_reg <= tx_st;
        dac_st_reg <= dac_st;

        // Si hubo reset vamos a estado = 0
        if (reset_sgn) begin
            rx_st <= 1'b0;
            tx_rq <= 1'b0;
            //animacion[5:0] <= 6'b0;
            alarma <= 1'b1;
            reset_sw <= 1'b0;
            tiempo_sel <= 3'd0;
            estado <= ST_0;
            //muestra = 16'd0;
        end

        // Analisis para pasar a estado 1
        else if (estado == ST_0 && rx_rq_reg && !rx_st) begin
            dato_rx_reg <= dato_rx;
            rx_st <= 1'b1;
        end

        else if (estado == ST_0 && !rx_rq_reg && rx_st) begin
            rx_st <= 1'b0;
            //animacion[0] = ~animacion[0];
            tiempo_sel <= 3'd0;
            // Si estoy en estado 0 y recibo "U", paso a estado 1
            estado = (dato_rx_reg == U_ASCII) ? ST_1 : ST_0;
        end

        // Estado 1, análisis para pasar a estado 2
        else if (estado == ST_1 && rx_rq_reg && !rx_st) begin
            dato_rx_reg <= dato_rx;
            rx_st <= 1'b1;
        end

        else if (estado == ST_1 && !rx_rq_reg && rx_st) begin
            rx_st <= 1'b0;
            //animacion[0] = ~animacion[0];
            // Si estoy en estado 1 y recibo "T" paso a estado 2, si no vuelvo a estado 0
            estado = (dato_rx_reg == T_ASCII) ? ST_2 : ST_0;
        end

        // Estado 2, análisis para pasar a estado 3 si recibo N
        else if (estado == ST_2 && rx_rq_reg && !rx_st) begin
            dato_rx_reg <= dato_rx;
            rx_st <= 1'b1;
        end

        else if (estado == ST_2 && !rx_rq_reg && rx_st) begin
            rx_st <= 1'b0;
            estado = (dato_rx_reg == N_ASCII) ? ST_3 : ST_0;
        end

        // Estado 3, determina el valor de la muestra para el dac spi en lo más alto o 0 Volts
        else if (estado == ST_3) begin
            muestra = (muestra == 16'd65535) ? 16'd0 : 16'd65535;
            // Próximo estado
            estado <= ST_4;
        end
        
        // Estado 4 Ordena conversión del dac spi y va estado 10
        else if (estado == ST_4 && !dac_st_reg && !dac_rq) begin
            dac_rq <= 1'b1;
        end

        else if (estado == ST_4 && dac_st_reg && dac_rq) begin
            dac_rq <= 1'b0;
            // Próximo estado
            estado = ST_10;
        end

        // Estado 5 idle
        else if (estado == ST_5) begin
            WatchDog <= 12'd0;  // Cancelo el WatchDog
            // Próximo estado
            estado = ST_5;
        end
        
        // Estado 10, fija samp_rate <= 16'd48000 y pasa a estado 11
        else if (estado == ST_10) begin
            samp_rate <= 16'd48000;  //fijo el sample rate en 48000
            estado <= ST_11;
        end         



	// Estado 11,  Determina tiempo_sel en base a samp_rate para operar y va estados 12 o 19
        else if (estado == ST_11) begin
            case (samp_rate)
                
               	16'd8000:
                begin
                    tiempo_sel <= 3'd0;
                    estado = ST_12;
                end
                
                16'd11025:
                begin
                    tiempo_sel <= 3'd1;
                    estado = ST_12;
                end
                
                16'd16000:
                begin
                    tiempo_sel <= 3'd2;
                    estado = ST_12;
                end
                
                16'd22050:
                begin
                    tiempo_sel <= 3'd3;
                    estado = ST_12;
                end
                
                16'd24000:
                begin
                    tiempo_sel <= 3'd4;
                    estado = ST_12;
                end
                
                16'd32000:
                begin
                    tiempo_sel <= 3'd5;
                    estado = ST_12;
                end
                
                16'd44100:
                begin
                    tiempo_sel <= 3'd6;
                    estado = ST_12;
                end

                16'd48000:
                begin
                    tiempo_sel <= 3'd7;
                    estado = ST_12;
                end

                16'd0:
                begin
                    estado = ST_12;         // Modo best efforts (tiempo_sel no importa)
                end

                default:
                begin
                    estado = ST_19;         // No encontré un samp_rate válido informo ERROR
                end
            endcase
        end
        

        // Estado 12, Envía "O" y voy a estado 13
        else if (estado == ST_12 && !tx_st_reg && !tx_rq) begin
            dato_tx_reg <= O_ASCII;
            tx_rq <= 1'b1;
        end

        else if (estado == ST_12 && tx_st_reg && tx_rq) begin
            tx_rq <= 1'b0;
            // Próximo estado
            estado = ST_13;
        end

        // Estado 13, Envía "K" y voy a estado 14
        else if (estado == ST_13 && !tx_st_reg && !tx_rq) begin
            dato_tx_reg <= K_ASCII;
            tx_rq <= 1'b1;
        end

        else if (estado == ST_13 && tx_st_reg && tx_rq) begin
            tx_rq <= 1'b0;
            // Próximo estado
            estado = ST_14;
        end

        // Estado 14, Envía "\n", ajusta variables de operación y voy a estado 15
        else if (estado == ST_14 && !tx_st_reg && !tx_rq) begin
            dato_tx_reg <= 8'd10;
            tx_rq <= 1'b1;
        end

        else if (estado == ST_14 && tx_st_reg && tx_rq) begin
            tx_rq <= 1'b0;
            // Ajusta variables de operación
            alarma <= 1'b0;
            gracia <= 2'd2;
            WatchDog <= 12'd4000;
            Ctn_anim <= 12'd4000;
            //animacion[5:0] <= 6'b1;
            // Próximo estado
            estado = ST_5;      // Antes 15
        end
        
        // Estado 15 entra operativo, determina la muestra del diente de sierra y vá a estado 16
        else if (estado == ST_15) begin
            muestra <= muestra + 16'd1365;
            // Próximo estado
            estado <= ST_16;
        end
        
        // Estado 16 (Operativo), evalua la muestra del diente de sierra para evitar exceso vá a estado 17
        else if (estado == ST_16) begin
            if (muestra == 16'd65520) muestra = 16'd0; // 65520 = 48 * 1365
            // Próximo estado
            estado <= ST_17;
        end
        
        // Estado 17 Detector de flanco ascendente de tiempo luego va a estado 18
        if (estado == ST_17 && tiempo && !tiempo_ant) begin
            estado = ST_18;
        end
        
        // Estado 18 Ordena conversión, WatchDog, Animación, va estado 15
        else if (estado == ST_18 && !dac_st_reg && !dac_rq) begin
            dac_rq <= 1'b1;
        end

        else if (estado == ST_18 && dac_st_reg && dac_rq) begin
            dac_rq <= 1'b0;
            // Código para el WatchDog
            if (WatchDog != 12'd0) begin
                WatchDog <= WatchDog - 1;
            end
            // Código para animación
            Ctn_anim <= Ctn_anim - 1;
            if (Ctn_anim == 12'd0) begin
                //animacion[5:0] <= (animacion[5]) ? 6'b1 : animacion[5:0] << 1;
                Ctn_anim <= 12'd4000;
            end
            // Próximo estado
            estado = ST_15;
        end

        // Estado 19, Envía "E" y voy a estado 20
        else if (estado == ST_19 && !tx_st_reg && !tx_rq) begin
            dato_tx_reg <= E_ASCII;
            tx_rq <= 1'b1;
        end

        else if (estado == ST_19 && tx_st_reg && tx_rq) begin
            tx_rq <= 1'b0;
            // Próximo estado
            estado = ST_20;
        end

        // Estado 20, Envía "R" y voy a estado 21
        else if (estado == ST_20 && !tx_st_reg && !tx_rq) begin
            dato_tx_reg <= R_ASCII;
            tx_rq <= 1'b1;
        end

        else if (estado == ST_20 && tx_st_reg && tx_rq) begin
            tx_rq <= 1'b0;
            // Próximo estado
            estado = ST_21;
        end

        // Estado 21, Envía "R" y voy a estado 22
        else if (estado == ST_21 && !tx_st_reg && !tx_rq) begin
            dato_tx_reg <= R_ASCII;
            tx_rq <= 1'b1;
        end

        else if (estado == ST_21 && tx_st_reg && tx_rq) begin
            tx_rq <= 1'b0;
            // Próximo estado
            estado = ST_22;
        end

        // Estado 22, Envía "O" y voy a estado 23
        else if (estado == ST_22 && !tx_st_reg && !tx_rq) begin
            dato_tx_reg <= O_ASCII;
            tx_rq <= 1'b1;
        end

        else if (estado == ST_22 && tx_st_reg && tx_rq) begin
            tx_rq <= 1'b0;
            // Próximo estado
            estado = ST_23;
        end

        // Estado 23, Envía "R" y voy a estado 24
        else if (estado == ST_23 && !tx_st_reg && !tx_rq) begin
            dato_tx_reg <= R_ASCII;
            tx_rq <= 1'b1;
        end

        else if (estado == ST_23 && tx_st_reg && tx_rq) begin
            tx_rq <= 1'b0;
            // Próximo estado
            estado = ST_24;
        end

        // Estado 24, Envía "\n", voy a estado 0
        else if (estado == ST_24 && !tx_st_reg && !tx_rq) begin
            dato_tx_reg <= 8'd10;
            tx_rq <= 1'b1;
        end

        else if (estado == ST_24 && tx_st_reg && tx_rq) begin
            tx_rq <= 1'b0;
            // Próximo estado
            estado = ST_0;
        end
        
        //*** Evaluación del WatchDog
        if (!medio_sg_ant && medio_sg && !alarma) begin
            // Detecto flanco ascendente de medio_sg (sucede entonces cada un segundo)
            if (gracia != 2'd0) begin
                gracia <= gracia -1;
            end

            else begin
                if (WatchDog == 12'd0) begin
                    WatchDog <= 12'd4000;
                end

                else begin
                    // Significa que no recibí muestras -> reset_sw
                    reset_sw <= 1'b1;
                end
            end
        end
        
        tiempo_ant <= tiempo; // Guardo el estado anterior de samp
        medio_sg_ant <= medio_sg;   // Guardo el estado para detectar flanco ascendente

    end

endmodule