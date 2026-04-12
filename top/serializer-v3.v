/* serializer-v3.v La versión tres realiza varias tareas.
1. Espera recibir "UTN"
2. Luego envía "UTNv3\n"
3. Espera cinco bytes que le indican el samp_rate (dos bytes), Type (Un byte), Vref (Dos bytes)
4. Luego envia "OK\n"
5 Lee constantemente la FIFO caracteres desde la PC a la tasa samp_rate* (2 o 4, según Type) caracteres (muestras reales o complejas de 16 bits) por segundo, de esta forma el hardware (P-2020) impone a GNU Radio el ritmo de funcionamiento. Cada vez que obtiene una muestra se la pasa al DAC.

% TODO Revisar
Significado de los leds
0 - Prende y Apaga cada un segundo
1 - Toggle cada vez que se recibe un dato o parte de la animación
*/

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
    output dac_spi_sync,  /*SYNC del AD5061*/

    output [15:0] dac_in,
    output dac_a0,
    output dac_a1,
    output dac_rs_neg,
    output dac_rstsel,    // 0 = reset a 0 scale, 1 = reset a mitad de escala
    output dac_ldac,      // Sirve para cargar registro
    output dac_wr_neg
);  

    /* --------------- State parameters --------------- */

    localparam ST_IDLE         = 6'd0,   // Espera "U"
               ST_RX_U        = 6'd1,   // Recibió "U", espera "T"
               ST_RX_T        = 6'd2,   // Recibió "T", espera "N"
               ST_TX_U        = 6'd3,   // Envía "U"
               ST_TX_T        = 6'd4,   // Envía "T"
               ST_TX_N        = 6'd5,   // Envía "N"
               ST_TX_v        = 6'd6,   // Envía "v"
               ST_TX_3        = 6'd7,   // Envía "3"
               ST_TX_NL       = 6'd8,   // Envía "\n" (fin de "UTNv3\n")
               ST_RX_SR_LO    = 6'd9,   // Recibe samp_rate byte bajo
               ST_RX_SR_HI    = 6'd10,  // Recibe samp_rate byte alto
               ST_VALIDATE    = 6'd11,  // Valida samp_rate y Type
               ST_TX_O        = 6'd12,  // Envía "O"
               ST_TX_K        = 6'd13,  // Envía "K"
               ST_TX_OK_NL    = 6'd14,  // Envía "\n" (fin de "OK\n")
               ST_RX_REAL_LO  = 6'd15,  // Recibe byte bajo (real)
               ST_RX_REAL_HI  = 6'd16,  // Recibe byte alto (real)
               ST_WAIT_TIME   = 6'd17,  // Espera tiempo de muestra
               ST_CONVERT     = 6'd18,  // Ordena conversión DAC 8822
               ST_TX_E        = 6'd19,  // Envía "E"
               ST_TX_R1       = 6'd20,  // Envía "R"
               ST_TX_R2       = 6'd21,  // Envía "R"
               ST_TX_O2       = 6'd22,  // Envía "O"
               ST_TX_R3       = 6'd23,  // Envía "R"
               ST_TX_ERR_NL   = 6'd24,  // Envía "\n" (fin de "ERROR_x\n"), va a ST_IDLE
               ST_RX_TYPE     = 6'd25,  // Recibe Type
               ST_RX_VREF_LO  = 6'd26,  // Recibe Vref byte bajo
               ST_RX_VREF_HI  = 6'd27,  // Recibe Vref byte alto
               ST_DAC_SPI     = 6'd28,  // Conversión DAC SPI (Vref)
               ST_TX_UNDER    = 6'd29,  // Envía "_"
               ST_TX_ERRTYPE  = 6'd30,  // Envía caracter de tipo de error
               ST_RX_IMAG_LO  = 6'd31,  // Recibe byte bajo (complejo)
               ST_RX_IMAG_HI  = 6'd32,  // Recibe byte alto (complejo)
               ST_CHECK_SAMP  = 6'd33;  // Decide si espera tiempo o va directo a conversión

    /* --------------- Signals --------------- */

    reg clk;
    reg [5:0]  estado = 6'b0;                    // estado indica en que estado está la placa
    reg rxf_245_reg;
    reg [7:0]  dato_rx, dato_rx_reg, dato_tx_reg;
    reg rx_rq_reg;
    reg rx_st = 1'b0;
    reg tx_rq = 1'b0;
    reg tx_st_reg;
    reg alarma = 1'b1;
    reg [31:0] muestra = 32'd0;                 // El valor que va al DAC
    reg [15:0] Vref = 16'd0;                    // Valor de Vref al DAC SPI
    reg [7:0] Data_Type = 8'd0;                 // Salva el Type recibido al comienzo
    reg [1:0] Data_Index = 2'd0;                // Indice del byte recibido
    reg dac_rq = 1'b0;
    reg dac_st_reg;
    reg dac_8822_rq = 1'b0;
    reg dac_8822_st_reg;
    reg tiempo_ant = 1'b0;
    //reg [5:0] animacion;
    reg [11:0] WatchDog = 12'd4000;             // Desciende por cada muestra recibida
    reg [11:0] Ctn_anim = 12'd4000;             // Desciende por cada muestra recibida y se recarga
    reg medio_sg_ant = 1'b0;
    reg [1:0]  gracia = 2'd2;                   // Segundos antes de WatchDog operativo
    
    // TODO si descomento lo que sigue no anda bien reset_sgn
    // reg reset_sgn = 1'b0;
    reg reset_sw = 1'b0;
    // reg reset_hw = 1'b0;
    reg [7:0]  tiempos;                         // 48, 44.1, 32, 24, 22.05, 16, 11.025, 8 KHz
    reg [2:0]  tiempo_sel = 3'd0;               // Tasa de muestra seleccionada
    reg [15:0] samp_rate = 16'd0;               // samp_rate recibido de gr-serializer
    reg [7:0] error_type = 8'd0;

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
    assign pin_L4B = (estado == ST_WAIT_TIME);  // Pasa a alto si está esperando para convertir (Idle)
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
        .io_245     (io_245),       // Bus de datos con el FTDI
        .txe_245    (txe_245),      // Del FTDI, vale 0 si está disponible para transmitir a la PC
        .rxf_245_in (rxf_245),      // Del FTDI, vale 0 cuando llegó un dato desde la PC
        .rx_245_out (rx_245),       // Del FTDI, vale 0 para solicitar lectura de dato que llegó de la PC y lo toma en el flanco positivo
        .wr_245     (wr_245),       // Del FTDI, en el flanco descendente almacena el dato a transmitir a la PC
        .rx_data    (dato_rx),      // Dato recibido de la PC hacia Mercurial
        .rx_rq      (rx_rq),        // Alto para avisar a Mercurial que llegó un dato
        .rx_st      (rx_st),        // Flanco positivo cuando el dato fue leído por Mercurial          
        .tx_data    (dato_tx_reg),  // Dato a transmitir a la PC desde Mercurial
        .tx_rq      (tx_rq),        // Alto para indicar que hay un dato desde Mercurial a transmitir
        .tx_st      (tx_st)         // Flanco positivo cuando el dato fue leído por este módulo
    );

    dac_spi dac_spi(
        .clock_in (clk),
        .reset    (reset_sgn),
    
        .dac_data (Vref),           // Vref a convertir por el DAC SPI
        .dac_rq   (dac_rq),         // Alto para indicar que hay una muestra para convertir
        .dac_st   (dac_st),         // Vale cero si el DAC está disponible para nueva conversión

        .sdata    (dac_spi_data),
        .bclk     (dac_spi_clk),
        .nsync    (dac_spi_sync)    // SYNC del AD5061  
    );
        
    dac_8822 dac_8822(
        .clk            (clk),              // TODO: Ver bien que clock le pasamos
        .reset          (reset_sgn),

        .data           (muestra),          // Muestra compleja a convertir
        .dac_rq         (dac_8822_rq),      // Alto para indicar que hay una muestra para convertir
        .dac_st         (dac_8822_st),      // Vale cero si el DAC está disponible para nueva conversión

        .dac_8822_data  (dac_in),           // se asigna la salida del modulo directo al dac 8822
        .dac_addr       ({dac_a1,dac_a0}),

        .dac_rs_neg     (dac_rs_neg),

        .dac_wr_neg     (dac_wr_neg),
        .dac_ldac       (dac_ldac),
        .dac_rstsel     (dac_rstsel),

        .dac_fake_led1  (fake_led1)
    );

    /* always */
    always @ (posedge clk) begin
        
        rx_rq_reg       <= rx_rq;
        tx_st_reg       <= tx_st;
        dac_st_reg      <= dac_st;
        dac_8822_st_reg <= dac_8822_st;

        if (reset_sgn) begin
            rx_st      <= 1'b0;
            tx_rq      <= 1'b0;
            //animacion[5:0] <= 6'b0;
            alarma     <= 1'b1;
            reset_sw   <= 1'b0;
            tiempo_sel <= 3'd0;
            estado     <= ST_IDLE;
            error_type <= 8'd0;
        end

        else begin
            case (estado)

                /* ----- Recibo UTN ----- */

                ST_IDLE: begin // Espero "U"
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end

                    else if (!rx_rq_reg && rx_st) begin
                        rx_st      <= 1'b0;
                        tiempo_sel <= 3'd0;
                        //animacion[0] = ~animacion[0];
                        if (dato_rx_reg == 8'd85) begin
                            alarma   <= 1'b0;
                            gracia   <= 2'd2;
                            WatchDog <= 12'd4000;
                            Ctn_anim <= 12'd4000;
                            estado   <= ST_RX_U;
                        end
                    end
                end

                ST_RX_U: begin // RX "U", espera "T"
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end

                    else if (!rx_rq_reg && rx_st) begin
                        rx_st  <= 1'b0;
                        //animacion[0] = ~animacion[0];
                        estado <= (dato_rx_reg == 8'd84) ? ST_RX_T : ST_IDLE;
                    end
                end

                ST_RX_T: begin // RX "T", espera "N"
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end

                    else if (!rx_rq_reg && rx_st) begin
                        rx_st  <= 1'b0;
                        //animacion[0] = ~animacion[0];
                        estado <= (dato_rx_reg == 8'd78) ? ST_TX_U : ST_IDLE;
                    end
                end

                /* ----- Envio "UTNv3\n" ----- */
                
                ST_TX_U: begin // Envía "U"
                    if (!tx_st_reg && !tx_rq) begin
                        st0         <= 1'b1;
                        st1         <= 1'b1;
                        dato_tx_reg <= 8'd85;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        st0    <= 1'b1;
                        st1    <= 1'b1;
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_T;
                    end
                end

                ST_TX_T: begin // Envía "T"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd84;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_N;
                    end
                end

                ST_TX_N: begin // Envía "N"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd78;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_v;
                    end
                end

                ST_TX_v: begin // Envía "v"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd118;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_3;
                    end
                end

                ST_TX_3: begin // Envía "3"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd51;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_NL;
                    end
                end

                ST_TX_NL: begin // Envía "\n"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd10;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_RX_SR_LO;
                    end
                end

                /* ---- Recepción de parámetros: samp_rate, type, vref ---- */

                ST_RX_SR_LO: begin // RX samp_rate byte bajo
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end

                    else if (!rx_rq_reg && rx_st) begin
                        rx_st          <= 1'b0;
                        //animacion[0] = ~animacion[0];
                        samp_rate[7:0] <= dato_rx_reg;
                        estado         <= ST_RX_SR_HI;
                    end
                end

                ST_RX_SR_HI: begin // RX samp_rate byte alto
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end

                    else if (!rx_rq_reg && rx_st) begin
                        rx_st           <= 1'b0;
                        //animacion[0] = ~animacion[0];
                        samp_rate[15:8] <= dato_rx_reg;
                        estado          <= ST_RX_TYPE;
                    end
                end

                ST_RX_TYPE: begin // RX type
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end

                    else if (!rx_rq_reg && rx_st) begin
                        rx_st     <= 1'b0;
                        Data_Type <= dato_rx_reg;
                        estado    <= ST_RX_VREF_LO;
                    end
                end

                ST_RX_VREF_LO: begin // RX vref byte bajo
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end
                    
                    else if (!rx_rq_reg && rx_st) begin
                        rx_st      <= 1'b0;
                        Vref[7:0]  <= dato_rx_reg;
                        estado     <= ST_RX_VREF_HI;
                    end
                end

                ST_RX_VREF_HI: begin // RX vref byte alto
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end

                    else if (!rx_rq_reg && rx_st) begin
                        rx_st      <= 1'b0;
                        Vref[15:8] <= dato_rx_reg;
                        estado     <= ST_VALIDATE;
                    end
                end

                /* ---- Validación de parámetros ---- */

                ST_VALIDATE: begin // valida samp_rate y Type
                    if (Data_Type == 8'd2 || Data_Type == 8'd4) begin
                        case (samp_rate)
                            16'd8000:  begin tiempo_sel <= 3'd0; estado <= ST_TX_O; end
                            16'd11025: begin tiempo_sel <= 3'd1; estado <= ST_TX_O; end
                            16'd16000: begin tiempo_sel <= 3'd2; estado <= ST_TX_O; end
                            16'd22050: begin tiempo_sel <= 3'd3; estado <= ST_TX_O; end
                            16'd24000: begin tiempo_sel <= 3'd4; estado <= ST_TX_O; end
                            16'd32000: begin tiempo_sel <= 3'd5; estado <= ST_TX_O; end
                            16'd44100: begin tiempo_sel <= 3'd6; estado <= ST_TX_O; end
                            16'd48000: begin tiempo_sel <= 3'd7; estado <= ST_TX_O; end
                            16'd0    : begin estado <= ST_TX_O; end // Best efforts
                            default  : begin
                                error_type <= 8'd83; // Error de samp_rate: "S"
                                estado     <= ST_TX_E;
                            end
                        endcase
                    end

                    else begin
                        error_type <= 8'd84; // Error de tipo: "T"
                        estado     <= ST_TX_E;
                    end
                end

                /* ---- Envío "OK\n" ---- */

                ST_TX_O: begin // Envía "O"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd79;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_K;
                    end
                end

                ST_TX_K: begin // Envía "K"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd75;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_OK_NL;
                    end
                end

                ST_TX_OK_NL: begin // Envía "\n"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd10;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_DAC_SPI;
                    end
                end

                /* ---- Conversión inicial Vref por DAC SPI ---- */

                ST_DAC_SPI: begin // TX vref al DAC SPI
                    if (!dac_st_reg && !dac_rq) begin
                        dac_rq <= 1'b1;
                    end

                    else if (dac_st_reg && dac_rq) begin
                        dac_rq <= 1'b0;
                        estado <= ST_RX_REAL_LO;
                    end
                end

                // ---- Loop operativo: recepción de muestras ----

                ST_RX_REAL_LO: begin // RX byte bajo real
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end

                    else if (!rx_rq_reg && rx_st) begin
                        rx_st        <= 1'b0;
                        muestra[7:0] <= dato_rx_reg;
                        estado       <= ST_RX_REAL_HI;
                    end
                end

                ST_RX_REAL_HI: begin // RX byte alto real
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end

                    else if (!rx_rq_reg && rx_st) begin
                        rx_st         <= 1'b0;
                        muestra[15:8] <= dato_rx_reg;
                        estado        <= (Data_Type == 8'd4) ? ST_RX_IMAG_LO : ST_CHECK_SAMP;
                    end
                end

                ST_RX_IMAG_LO: begin // RX byte bajo imaginaria
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end

                    else if (!rx_rq_reg && rx_st) begin
                        rx_st          <= 1'b0;
                        muestra[23:16] <= dato_rx_reg;
                        estado         <= ST_RX_IMAG_HI;
                    end
                end

                ST_RX_IMAG_HI: begin // RX byte alto imaginario
                    if (rx_rq_reg && !rx_st) begin
                        dato_rx_reg <= dato_rx;
                        rx_st       <= 1'b1;
                    end

                    else if (!rx_rq_reg && rx_st) begin
                        rx_st          <= 1'b0;
                        muestra[31:24] <= dato_rx_reg;
                        estado         <= ST_CHECK_SAMP;
                    end
                end

                ST_CHECK_SAMP: begin // Decide entre best-efforts y cadencia de tiempo
                    estado <= (samp_rate == 16'd0) ? ST_CONVERT : ST_WAIT_TIME;
                end

                ST_WAIT_TIME: begin // Espera flanco ascendente de tiempo
                    if (tiempo && !tiempo_ant)
                        estado <= ST_CONVERT;
                end

                ST_CONVERT: begin // Ordena conversión DAC 8822, WatchDog, animación
                    if (!dac_8822_st_reg && !dac_8822_rq) begin
                        dac_8822_rq <= 1'b1;
                    end

                    else if (dac_8822_st_reg && dac_8822_rq) begin
                        dac_8822_rq <= 1'b0;

                        // WatchDog
                        if (WatchDog != 12'd0)
                            WatchDog <= WatchDog - 1;

                        // Animación
                        Ctn_anim <= Ctn_anim - 1;
                        if (Ctn_anim == 12'd0) begin
                            //animacion[5:0] <= (animacion[5]) ? 6'b1 : animacion[5:0] << 1;
                            Ctn_anim <= 12'd4000;
                        end

                        estado <= ST_RX_REAL_LO;
                    end
                end

                /* ---- Envío "ERROR_x\n" ---- */

                ST_TX_E: begin // TX "E"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd69;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_R1;
                    end
                end

                ST_TX_R1: begin // TX "R"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd82;
                        tx_rq       <= 1'b1;
                    end
                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_R2;
                    end
                end

                ST_TX_R2: begin // TX "R"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd82;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_O2;
                    end
                end

                ST_TX_O2: begin // TX "O"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd79;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_R3;
                    end
                end

                ST_TX_R3: begin // TX "R"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd82;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_UNDER;
                    end
                end

                ST_TX_UNDER: begin // TX "_"
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd95;
                        tx_rq       <= 1'b1;
                    end
                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_ERRTYPE;
                    end
                end

                ST_TX_ERRTYPE: begin // TX char tipo de error ("S" o "T")
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= error_type;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq  <= 1'b0;
                        estado <= ST_TX_ERR_NL;
                    end
                end

                ST_TX_ERR_NL: begin // TX "\n", luego reset vía reset_sw
                    if (!tx_st_reg && !tx_rq) begin
                        dato_tx_reg <= 8'd10;
                        tx_rq       <= 1'b1;
                    end

                    else if (tx_st_reg && tx_rq) begin
                        tx_rq    <= 1'b0;
                        reset_sw <= 1'b1;
                    end
                end
            endcase
        end

        /* ---- WatchDog ---- */
        if (!medio_sg_ant && medio_sg && !alarma) begin
            // Flanco ascendente de medio_sg: ocurre una vez por segundo
            if (gracia != 2'd0) begin
                gracia <= gracia - 1;
            end

            else begin
                if (WatchDog == 12'd0)
                    WatchDog <= 12'd4000;
                else
                    reset_sw <= 1'b1;   // Sin muestras recibidas
            end
        end

        tiempo_ant   <= tiempo;     // Guardo el estado anterior de tiempo
        medio_sg_ant <= medio_sg;   // Guardo el estado para detectar flanco ascendente
    end
endmodule