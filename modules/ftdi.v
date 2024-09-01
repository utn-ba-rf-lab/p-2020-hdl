/* Pines del FTDI
RXF(output) ->  'high' dont read from fifo. 'low' data availabe in the fifo.

TXE(output) -> 'high' dont write into fifo. 'low' data can be written to fifo.

RD(input) -> Poniendolo en 'low' le digo al FTDI que voy a leer el dato. Una vez que lo leo lo paso a 'high'

WR(input) -> Writes the data byte on the D0...D7 pins into the transmit FIFO buffer when WR# goes from high to low. 
*/

//  Cuando recibo algo desde la pc lo tengo que transmitir al top module
//  Cuando recibo algo desde el top module lo tengo que transmitir a la PC

//  =========  from_ftdi_valid  ==========   to_top_valid    ==========
//  |       |  ------------>    |        |   ------------>   |        |
//  |       |  <------------    |        |   <------------   |        |
//  |       |  from_ftdi_ready  | ESTE   |   to_top_ready    |  TOP   |
//  |   PC  |                   | MODULE |                   | MODULE |
//  |       |  to_ftdi_ready    |        |   from_top_ready  |        |
//  |       |  ------------>    |        |   ------------>   |        |
//  |       |  <------------    |        |   <------------   |        |
//  =========  to_ftdi_valid    ==========   from_top_valid  ==========

module ftdi(
    input  clock_in,
    input  reset,
    
    // comunicacion con la pc/ftdi
    input   from_ftdi_valid_n, // Del FTDI, '0' dato disponible para leer en la placa.
    output  from_ftdi_ready_n, // Del FTDI, '0' solicito lectura del dato que llegó. lo toma en el flanco positivo.
    output  to_ftdi_valid_n,   // Del FTDI, en el flanco descendente almacena el dato a transmitir a la PC
    input   to_ftdi_ready_n,   // Del FTDI, '0' la placa puede transmitir a la PC.
    
    // comunicacion con el top module
    input   from_top_valid,
    output  from_top_ready,
    output  to_top_valid,
    input   to_top_ready,
    
    inout  [7:0] io_245,            // Bus de datos con el FTDI
    output [7:0] from_rx_to_top,    // Buffer del dato recibido 
    input  [7:0] from_top_to_tx,    // Buffer del dato a enviar
);

    /* ---------- estados ---------- */

    localparam ST_RX_IDLE    = 3'd0;    // Espera la llegada de un dato desde la PC
    localparam ST_RX_STORE   = 3'd1;    // Carga el dato en from_rx_to_top
    localparam ST_RX_READY   = 3'd2;    // Avisa al top module del dato que llega
    localparam ST_RX_CONFIRM = 3'd3;    // El top module confimo que le llego el dato
    localparam ST_RX_FREE    = 3'd4;    // top module libera el bus
    
    localparam ST_TX_IDLE    = 3'd0;    // Espera la llegada de un dato desde el top module
    localparam ST_TX_STORE   = 3'd1;    // Se almacena el dato recibido
    localparam ST_TX_READY   = 3'd2;    // Confirmamos al top module que tomamos el dato
    localparam ST_TX_CONFIRM = 3'd3;    // Top module nos notifica que le llego nuestra confirmacion
    localparam ST_TX_FREE    = 3'd4;    // Se libera el bus tx

    /* ---------- Registers ---------- */
    reg [3:0] estado_rx = ST_RX_IDLE;
    reg [3:0] estado_tx = ST_TX_IDLE;
    
    reg [7:0] from_top_to_tx_reg;
    reg [7:0] from_rx_to_top_reg;
    
    reg from_ftdi_ready_n_reg;
    reg from_top_ready_reg;
    reg to_top_valid_reg;
    reg to_ftdi_valid_n_reg;
    

    // TODO: buscar tristate buffers
    assign io_245 = (estado_tx == ST_TX_READY && !to_ftdi_ready_n) ? from_top_to_tx_reg : 8'bz;
    
    /* ---------- always ---------- */
    always @ (posedge clock_in) begin
        
        to_top_valid_reg        <= to_top_valid;
        from_top_ready_reg      <= from_top_ready;
        from_ftdi_ready_n_reg   <= from_ftdi_ready_n;
        to_ftdi_valid_n_reg     <= to_ftdi_valid_n;
      

        // Si hubo reset vamos a estado Idle
        if (reset) begin
            estado_tx  <= ST_TX_IDLE;
            estado_rx  <= ST_RX_IDLE;
        end

        else begin
            
            /* ---------- Maquina de estados RX ---------- */
            case (estado_rx)

                ST_RX_IDLE: begin
                    // Hay un dato disponible desde FTDI?
                    if (!from_ftdi_valid_n) begin
                        from_ftdi_ready_n_reg <= 1'b0;  // Solicito lectura del dato al FTDI
                        estado_rx <= ST_RX_STORE;
                    end
                end

                ST_RX_STORE: begin
                    from_rx_to_top_reg <= io_245;        // Almaceno dato recibido desde FTDI. NO SE SI VA A ANDAR
                    from_ftdi_ready_n_reg <= 1'b1;      // indico a ftdi que termine la lectura
                    to_top_valid_reg <= 1'b1;            // aviso que me llego un dato para pasar a otro modulo                
                    estado_rx <= ST_RX_CONFIRM;
                end

                ST_RX_CONFIRM: begin
                    // el top modulo leyo el dato?
                    if(to_top_ready == 1'b1) begin
                        //to_top_valid_reg <= 1'b0; 
                        from_rx_to_top <= from_rx_to_top_reg;
                        estado_rx <= ST_RX_FREE;  
                    end
                end

                ST_RX_FREE: begin                   // Este estado está al pedo
                    if(to_top_ready == 1'b0) begin
                        to_top_valid_reg <= 1'b0; 
                        estado_rx <= ST_RX_IDLE;
                    end
                end

                default: estado_rx <= ST_RX_IDLE;

            endcase

            /* ---------- Maquina de estados TX ---------- */
            case (estado_tx)

                ST_TX_IDLE: begin
                    // El top module tiene algo para enviar?
                    if (from_top_valid && !to_ftdi_ready_n) begin
                        from_top_ready_reg <= 1'b1;     // Le aviso a top que leo el dato
                        estado_tx <= ST_TX_STORE;
                    end
                end

                ST_TX_STORE: begin
                    from_top_to_tx_reg <= from_top_to_tx;
                    to_ftdi_valid_n_reg   <= 1'b1;    // le aviso al ftdi que le mando un dato
                    from_top_ready_reg    <= 1'b0;
                    estado_tx <= ST_TX_READY;
                end

                // TODO: Ver si se puede quitar este estado y mover el flag al estado anterior
                ST_TX_READY: begin
                    if(!to_ftdi_ready_n) begin
                        io_245 <= from_top_to_tx_reg;
                        estado_tx <= ST_TX_CONFIRM;
                    end
                end

                ST_TX_CONFIRM: begin
                    if(to_ftdi_ready_n) begin
                        to_ftdi_valid_n_reg <= 1'b1;
                        estado_tx <= ST_TX_IDLE;
                    end
                end
            endcase
        end
    end    
endmodule