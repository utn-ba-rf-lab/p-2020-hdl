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
    
    inout  [7:0] io_245,         // Bus de datos con el FTDI
    input  to_ftdi_ready,        // txe_245 del FTDI.'0' disponible para transmitir a la PC
    input  from_ftdi_valid,      // rxf_245 del FTDI.'0' llegó un dato desde la PC
    output from_ftdi_ready,      // rd del FTDI. '0' para leer dato que llego desde PC.
    output to_ftdi_valid,        // wr del FTDI. '0' indico la transmision de un dato hacia PC.
    
    output [7:0] from_ftdi_data, // Dato recibido de la PC hacia Mercurial
    output to_top_valid,         // rx_rq. '1' para avisar a Mercurial que llegó un dato
    input  to_top_ready,         // rx_st. Flanco positivo cuando el dato fue leído por Mercurial

    input  [7:0] to_ftdi_data,   // Dato a transmitir a la PC desde Mercurial
    input  from_top_valid,       // tx_rq Alto para indicar que hay un dato desde Mercurial a transmitir
    output from_top_ready        // tx_st Flanco positivo cuando el dato fue leído por este módulo
);

    /* ---------- estados ---------- */

    localparam ST_IDLE = 3'd0;  // espera dato para recibir desde ftdi o para enviarle.
    
    localparam ST_RX_1 = 3'd1;  // Espera la llegada de un dato desde la PC
    localparam ST_RX_2 = 3'd2;  // Carga el dato en from_rx_to_top
    localparam ST_RX_3 = 3'd3;  // Avisa al top module del dato que llega
    localparam ST_RX_4 = 3'd4;  // El top module confimo que le llego el dato
   
    localparam ST_TX_1 = 3'd5;  // Espera la llegada de un dato desde el top module
    localparam ST_TX_2 = 3'd6;  // Se almacena el dato recibido
    localparam ST_TX_3 = 3'd7;  // Confirmamos al top module que tomamos el dato
    localparam ST_TX_4 = 3'd8;  // Top module nos notifica que le llego nuestra confirmacion

    /* ---------- Registers ---------- */

    reg [2:0] estado_sig    = 3'd0;
    reg [2:0] estado_actual = 3'd0;

    reg to_ftdi_ready_reg;       
    reg from_ftdi_valid_reg = 1'b1;

    reg to_top_valid;
    reg to_top_ready_reg;
    reg from_top_valid_reg;
    reg from_top_ready;
    
    reg [7:0] to_ftdi_data_in;
    
    // output enable
    reg oe = 1'b0;
    assign io_245 = oe ? to_ftdi_data_in : 8'bZ;

    /* ---------- always ---------- */
    always @ (posedge clock_in) begin
        
        to_ftdi_ready_reg   <= to_ftdi_ready;
        from_ftdi_valid_reg <= from_ftdi_valid;
        to_top_ready_reg    <= to_top_ready;
        from_top_valid_reg  <= from_top_valid;
        estado_actual       <= estado_sig;
        
        // Si hubo reset vamos a estado Idle
        if (reset) begin
            estado_sig <= 3'd0;
            estado_actual <= 3'd0;
            to_top_valid <= 1'b0;
            from_top_ready <= 1'b0;
            oe = 1'b0;
            to_ftdi_valid = 1'b1;
        end

        else begin

            case (estado_actual)
                
                ST_IDLE: begin
                    if(from_top_valid_reg && !to_ftdi_ready_reg) begin
                        oe = 1'b1;
                        to_ftdi_valid <= 1'b1;
                        estado_sig <= ST_TX_1;
                    end

                    else if (!from_ftdi_valid_reg) begin
                        oe = 1'b0;
                        from_ftdi_ready <= 1'b0;
                        estado_sig <= ST_RX_1;
                    end
                end

                /* ----- MAQUINA PARA TX HACIA FTDI ----- */
                ST_TX_1: begin
                    to_ftdi_data_in <= to_ftdi_data;
                    from_top_ready <= 1'b1;
                    estado_sig <= ST_TX_2;
                end

                ST_TX_2: begin
                    to_ftdi_valid <= 1'b0;
                    estado_sig <= ST_TX_3;
                end

                ST_TX_3: begin
                    to_ftdi_valid <= 1'b1;
                    from_top_ready  <= 1'b0;
                    estado_sig <= ST_TX_4;
                end

                ST_TX_4: begin
                    if(!from_top_valid_reg) begin
                        estado_sig <= ST_IDLE;
                    end
                end

                /* ----- MAQUINA PARA RX DESDE FTDI ----- */
                ST_RX_1: begin
                    from_ftdi_data = io_245;
                    from_ftdi_ready <= 1'b1;
                    estado_sig <= ST_RX_2;
                end

                ST_RX_2: begin
                    to_top_valid <= 1'b1;
                    estado_sig <= ST_RX_3;
                end

                ST_RX_3: begin
                    if(to_top_ready_reg) begin
                        to_top_valid <= 1'b0;
                        estado_sig <= ST_RX_4;
                    end
                end

                ST_RX_4: begin
                    if(!to_top_ready_reg) begin
                        estado_sig <= ST_IDLE;
                    end
                end 

                default: begin
                    estado_sig <= ST_IDLE;
                end
            endcase
        end   
    end 
        
endmodule