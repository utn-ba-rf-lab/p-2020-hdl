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
    
    inout  [7:0] io_245,    // Bus de datos con el FTDI
    input  txe_245,         // Del FTDI, vale 0 si está disponible para transmitir a la PC
    input  rxf_245_in,      // Del FTDI, vale 0 cuando llegó un dato desde la PC
    output rx_245_out,      // Del FTDI, vale 0 para solicitar lectura de dato que llegó de la PC y lo toma en el flanco positivo
    output wr_245,          // Del FTDI, en el flanco descendente almacena el dato a transmitir a la PC
    
    output [7:0] rx_data,   // Dato recibido de la PC hacia Mercurial
    output rx_rq,           // Alto para avisar a Mercurial que llegó un dato
    input  rx_st,           // Flanco positivo cuando el dato fue leído por Mercurial

    input  [7:0] tx_data,   // Dato a transmitir a la PC desde Mercurial
    input  tx_rq,           // Alto para indicar que hay un dato desde Mercurial a transmitir
    output tx_st            // Flanco positivo cuando el dato fue leído por este módulo
);

    /* ---------- estados ---------- */

    localparam ST_IDLE = 3'd0;
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
    //reg [2:0] estado_ftdi_tx = 3'd0;
    reg txe_245_reg;
    reg rxf_245_reg = 1'b1;
    reg rx_rq;
    reg rx_st_reg;
    reg tx_rq_reg;
    reg tx_st;
    reg [7:0] tx_data_in;
    reg oe = 1'b0;
    assign io_245 = oe ? tx_data_in : 8'bZ;

    /* ---------- always ---------- */
    always @ (posedge clock_in) begin
        
        txe_245_reg <= txe_245;
        rxf_245_reg <= rxf_245_in;
        rx_st_reg <= rx_st;
        tx_rq_reg <= tx_rq;
        estado_actual <= estado_sig;
        
        // Si hubo reset vamos a estado Idle
        if (reset) begin
            estado_sig <= 3'd0;
            estado_actual <= 3'd0;
            rx_rq <= 1'b0;
            tx_st <= 1'b0;
            oe = 1'b0;
            wr_245 = 1'b1;
        end

        else begin

            case (estado_actual)
                
                ST_IDLE: begin
                    if(tx_rq_reg && !txe_245_reg) begin
                        oe = 1'b1;
                        wr_245 <= 1'b1;
                        estado_sig <= ST_TX_1;
                    end

                    else if (!rxf_245_reg) begin
                        oe = 1'b0;
                        rx_245_out <= 1'b0;
                        estado_sig <= ST_RX_1;
                    end
                end

                // MAQUINA PARA TX HACIA FTDI
                ST_TX_1: begin
                    tx_data_in <= tx_data;
                    tx_st <= 1'b1;
                    estado_sig <= ST_TX_2;
                end

                ST_TX_2: begin
                    wr_245 <= 1'b0;
                    estado_sig <= ST_TX_3;
                end

                ST_TX_3: begin
                    wr_245 <= 1'b1;
                    tx_st  <= 1'b0;
                    estado_sig <= ST_TX_4;
                end

                ST_TX_4: begin
                    if(!tx_rq_reg) begin
                        estado_sig <= ST_IDLE;
                    end
                end

                // MAQUINA PARA RX DESDE FTDI
                ST_RX_1: begin
                    rx_data = io_245;
                    rx_245_out <= 1'b1;
                    estado_sig <= ST_RX_2;
                end

                ST_RX_2: begin
                    rx_rq <= 1'b1;
                    estado_sig <= ST_RX_3;
                end

                ST_RX_3: begin
                    if(rx_st_reg) begin
                        rx_rq <= 1'b0;
                        estado_sig <= ST_RX_4;
                    end
                end

                ST_RX_4: begin
                    if(!rx_st_reg) begin
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