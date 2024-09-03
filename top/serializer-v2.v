/* serializer.v V2 realiza varias tareas.
1. Espera recibir "UTN"
2. Luego envía "UTNv2\n"
3. Espera dos bytes que le indican el samp_rate
4. Luego envia "OK\n"
5 Lee constantemente la FIFO caracteres desde la PC a la tasa samp_rate*2 caracteres (muestras) por segundo, puesto que una muestra son dos caracteres, de esta forma Mercurial (PF-2019) impone a GNU Radio el ritmo de funcionamiento.
Cada vez que obtiene una muestra se la pasa al DAC.
*/

module top_module (

    input  hwclk,        // Clock
    input  reset_btn,    // Botón de reset
    inout  [7:0] io_245, // Bus de datos con el FTDI
    input  txe_245,
    input  rxf_245,
    
    output rx_245,
    output wr_245,
    output led0,
    output led1,
    output pin_L23B,
    output pin_L4B,
    output dac_spi_data,
    output dac_spi_clk,
    output dac_spi_sync  /*SYNC del AD5061*/
);  

    /* --------------- Signals --------------- */

    reg clk;
    reg pllclk;
    reg [4:0]  estado = 5'b0;       // estado indica en que estado está la placa
    reg rxf_245_reg;
    reg [7:0] dato_rx;
    reg [7:0] dato_rx_reg;
    reg [7:0] dato_tx_reg;
    
    reg rx_rq_reg;
    reg rx_st = 1'b0;
    reg tx_rq = 1'b0;
    reg tx_st_reg;
    
    reg alarma = 1'b1;
    reg [15:0] muestra = 16'd0;     // El valor que va al DAC
    reg dac_rq = 1'b0;
    reg dac_st_reg;
    reg tiempo_ant = 1'b0;
    reg [11:0] WatchDog = 12'd4000; // Desciende por cada muestra recibida
    reg [11:0] Ctn_anim = 12'd4000; // Desciende por cada muestra recibida y se recarga
    reg medio_sg_ant = 1'b0;
    reg [1:0] gracia = 2'd2;        // Cantidad de segundos antes de WatchDog operativo
    reg reset_sw = 1'b0;
    reg [7:0]  tiempos;             // 48, 44.1, 32, 24, 22.05, 16, 11.025, 8 KHz
    reg [2:0]  tiempo_sel = 3'd0;   // Tasa de muestra seleccionada
    reg [15:0] samp_rate  = 16'd0;   // samp_rate recibido de gr-serializer
    
    /* --------------- Assignments --------------- */

    assign clk       = hwclk;
    assign led0      = alarma;
    assign pin_L23B  = tiempo;
    assign rxf_245   = rxf_245_reg;
    assign pin_L4B   = (estado == 5'd17);   // Pasa a alto si está esperando para convertir (Idle)
    assign tiempo    = tiempos[tiempo_sel];
    assign reset_sgn = (reset_hw | reset_sw);

    /* --------------- Modules instances --------------- */

    pll pll(
        .clock_in   (clk),
        .clock_out  (pllclk)
    );

    temporizador temporizador(
        .clock_in   (pllclk),
        .reset_btn  (reset_btn),
        .medio_sg   (medio_sg),
        .rst_out    (reset_hw),
        .samp_rates (tiempos),
        .latido     (led1)
    );
    
    ftdi ftdi(
        .clock_in           (clk),
        .reset              (reset_sgn),
        .io_245             (io_245),      // Bus de datos con el FTDI
        .to_ftdi_ready      (txe_245),     // FTDI, '0' si está disponible para transmitir a la PC
        .from_ftdi_valid    (rxf_245),     // FTDI, '0' cuando llegó un dato desde la PC
        .from_ftdi_ready    (rx_245),      // FTDI, '0' para solicitar lectura de dato que llegó de la PC y lo toma en el flanco pos
        .to_ftdi_valid      (wr_245),      // FTDI, en el flanco neg almacena el dato a transmitir a la PC
        .from_ftdi_data     (dato_rx),     // Dato recibido de la PC hacia Mercurial
        .to_top_valid       (rx_rq),       // Alto para avisar a Mercurial que llegó un dato
        .to_top_ready       (rx_st),       // Flanco positivo cuando el dato fue leído por Mercurial          
        .to_ftdi_data       (dato_tx_reg), // Dato a transmitir a la PC desde Mercurial
        .from_top_valid     (tx_rq),       // Alto para indicar que hay un dato desde Mercurial a transmitir
        .from_top_ready     (tx_st)        // Flanco pos cuando el dato fue leído por este módulo
    );

    dac_spi dac_spi(
        .clock_in (clk),
        .reset    (reset_sgn),
    
        .dac_data (muestra),    // Muestra a convertir
        .dac_rq   (dac_rq),     // Alto para indicar que hay una muestra para convertir
        .dac_st   (dac_st),     // Vale cero si el DAC está disponible para nueva conversión

        .sdata    (dac_spi_data),
        .bclk     (dac_spi_clk),
        .nsync    (dac_spi_sync)// SYNC del AD5061  
    );

    // Estados de la placa
    // estado = 0 Inicio, espera "U", si no va estado 0
    // estado = 1 Recibió "U" espera "T", si no va estado 0
    // estado = 2 Recibió "T" espera "N", si no va estado 0
    // estado = 3 Envía "U"
    // estado = 4 Envía "T"
    // estado = 5 Envía "N"
    // estado = 6 Envía "v"
    // estado = 7 Envía "2"
    // estado = 8 Envía "\n"
    // estado = 9 Recibe samp_rate bajo     
    // estado = 10 Recibe samp_rate alto, va estado 11
    // estado = 11 Determina tiempo_sel en base a samp_rate para operar, va estados 12 o 19
    // estado = 12 Envía "O"
    // estado = 13 Envía "K"
    // estado = 14 Envía "\n", ajusta variables de operación
    // estado = 15 Operativo recibe byte bajo
    // estado = 16 Operativo recibe byte alto
    // estado = 17 Operativo espera tiempo de muestra
    // estado = 18 Operativo Ordena conversión, WatchDog, Animación, va estado 14
    // estado = 19 Envía "E"
    // estado = 20 Envía "R"
    // estado = 21 Envía "R"
    // estado = 22 Envía "O"
    // estado = 23 Envía "R"
    // estado = 24 Envía "\n", va estado 0

    /* ---------- always ---------- */
    always @ (posedge clk) begin
        
        rx_rq_reg  <= rx_rq;
        tx_st_reg  <= tx_st;
        dac_st_reg <= dac_st;

        // Si hubo reset vamos a estado = 0
        if (reset_sgn) begin
            rx_st      <= 1'b0;
            tx_rq      <= 1'b0;
            alarma     <= 1'b1;
            estado     <= 5'd0;
            reset_sw   <= 1'b0;
            tiempo_sel <= 3'd0;
        end
        
        // Init OK
        else if (init_rdy == 2'b1) begin 
            tx_rq    <= 1'b0;
            // Ajusta variables de operación
            alarma   <= 1'b0;
            gracia   <= 2'd2;
            WatchDog <= 12'd4000;
            Ctn_anim <= 12'd4000;
            estado = 5'd15; 
        end

        // Init ERROR
        else if (init_rdy == 2'b2) begin
        end

        // TODO: remover este else if
        else if (estado == 5'd14 && tx_st_reg && tx_rq) begin
            tx_rq <= 1'b0;
            // Ajusta variables de operación
            alarma <= 1'b0;
            gracia <= 2'd2;
            WatchDog <= 12'd4000;
            Ctn_anim <= 12'd4000;
            estado = 5'd15; 
        end
        
        /* ----- Recepcion de datos de la senal ----- */

        // Estado 15 --> Recibe byte bajo
        else if (estado == 5'd15 && rx_rq_reg && !rx_st) begin
            dato_rx_reg <= dato_rx;
            rx_st <= 1'b1;
        end

        else if (estado == 5'd15 && !rx_rq_reg && rx_st) begin
            rx_st <= 1'b0;
            muestra[7:0] <= dato_rx_reg;
            estado = 5'd16; 
        end
        
        // Estado 16 --> Recibe byte bajo
        // Va a estado 17 o 18 si esta en best efforts
        else if (estado == 5'd16 && rx_rq_reg && !rx_st) begin
            dato_rx_reg <= dato_rx;
            rx_st <= 1'b1;
        end

        else if (estado == 5'd16 && !rx_rq_reg && rx_st) begin
            rx_st <= 1'b0;
            muestra[15:8] <= dato_rx_reg;
            estado <= (samp_rate == 16'd0) ? 5'd18 : 5'd17; 
        end

        // Estado 17 --> Detector de flanco pos de tiempo luego va a estado 18
        if (estado == 5'd17 && tiempo && !tiempo_ant) begin
            estado = 5'd18;
        end
        
        // Estado 18 --> Ordena conversión, WatchDog, Animación, va a estado 15
        else if (estado == 5'd18 && !dac_st_reg && !dac_rq) begin
            dac_rq <= 1'b1;
        end

        else if (estado == 5'd18 && dac_st_reg && dac_rq) begin
            
            dac_rq <= 1'b0;
            
            // Código para el WatchDog
            if (WatchDog != 12'd0)
                WatchDog <= WatchDog - 1;
            
            // Código para animación
            Ctn_anim <= Ctn_anim - 1;
            if (Ctn_anim == 12'd0)
                Ctn_anim <= 12'd4000;
        
            estado = 5'd15; 
        end

        //*** Evaluación del WatchDog
        if (!medio_sg_ant && medio_sg && !alarma) begin
            
            // Detecto flanco ascendente de medio_sg (sucede entonces cada un segundo)
            if (gracia != 2'd0)
                gracia <= gracia -1;

            else begin
                if (WatchDog == 12'd0)
                    WatchDog <= 12'd4000;

                else // Significa que no recibí muestras -> reset_sw
                    reset_sw <= 1'b1;
            end
        end
        
        tiempo_ant   <= tiempo;       // Guardo el estado anterior de samp
        medio_sg_ant <= medio_sg;   // Guardo el estado para detectar flanco ascendente
    end
endmodule