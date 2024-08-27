/* Pines del FTDI
RXF(output) ->  'high' dont read from fifo. 'low' data availabe in the fifo.

TXE(output) -> 'high' dont write into fifo. 'low' data can be written to fifo.

RD(input) -> Poniendolo en 'low' le digo al FTDI que voy a leer el dato. Una vez que lo leo lo paso a 'high'

WR(input) -> Writes the data byte on the D0...D7 pins into the transmit FIFO buffer when WR# goes from high to low. 
*/

module ftdi(
    input  clock_in,
    input  reset,
    
    inout  [7:0] io_245,    // Bus de datos con el FTDI
    input  tx_available,    // Del FTDI, '0' la placa puede transmitir a la PC.
    output tx_ftdi_flag,    // Del FTDI, en el flanco descendente almacena el dato a transmitir a la PC
    input  rx_available,    // Del FTDI, '0' dato disponible para leer en la placa.
    output rx_ftdi_flag,    // Del FTDI, '0' solicito lectura del dato que llegó. lo toma en el flanco positivo.

    output [7:0] rx_data,   // Buffer del dato recibido 
    output rx_valid,        // 'high' para avisar al top module que llegó un dato
    input  rx_ready,        // Flanco positivo cuando el dato fue leído por Mercurial

    input  [7:0] tx_data,   // Buffer del dato a enviar
    input  tx_valid,        // 'high' para indicar que el top module quiere transmitir un dato
    output tx_ready         // Flanco positivo cuando el dato fue leído por este módulo
);

    /* ---------- estados ---------- */

    localparam ST_RX_IDLE    = 3'd0;    // Espera la llegada de un dato desde la PC
    localparam ST_RX_STORE   = 3'd1;    // Carga el dato en rx_data
    localparam ST_RX_READY   = 3'd2;    // Avisa al top module del dato que llega
    localparam ST_RX_CONFIRM = 3'd3;    // El top module confimo que le llego el dato
    localparam ST_RX_FREE    = 3'd4;    // top module libera el bus
    
    localparam ST_TX_IDLE    = 3'd0;    // Espera la llegada de un dato desde el top module
    localparam ST_TX_STORE   = 3'd1;    // Se almacena el dato recibido
    localparam ST_TX_READY   = 3'd2;    // Confirmamos al top module que tomamos el dato
    localparam ST_TX_CONFIRM = 3'd3;    // Top module nos notifica que le llego nuestra confirmacion
    localparam ST_TX_FREE    = 3'd4;    // Se libera el bus tx

    /* ---------- Registers ---------- */
    
    reg [2:0] estado_rx = 3'd0;
    reg [2:0] estado_tx = 3'd0;

    reg tx_available_reg;
    reg rx_available_reg = 1'b1;
    reg rx_valid;
    reg tx_ready;
    reg rx_ready_reg;
    reg tx_valid_reg;
    reg [7:0] tx_data_in;
    
    // Output Enable
    reg oe = 1'b0;              

    /* ---------- assignments ---------- */

    assign io_245 = oe ? tx_data_in : 8'bZ;

    /* ---------- always ---------- */
    always @ (posedge clock_in) begin
        
        tx_available_reg <= tx_available;
        rx_available_reg <= rx_available;
        rx_ready_reg     <= rx_ready;
        tx_valid_reg     <= tx_valid;
        
        // Si hubo reset vamos a estado Idle
        if (reset) begin
            oe = 1'b0;
            rx_valid <= 1'b0;
            tx_ready <= 1'b0;
            tx_ftdi_flag = 1'b1;
            estado_tx  <= ST_TX_IDLE;
            estado_rx  <= ST_RX_IDLE;
        end

        else begin
            
            /* ---------- Maquina de estados RX ---------- */
            case (estado_rx)

                ST_RX_IDLE: begin
                    // Hay un dato disponible?
                    if (!rx_available_reg) begin
                        oe = 1'b0;                // Aseguro lectura del bus
                        rx_ftdi_flag <= 1'b0;     // Solicito lectura del dato al FTDI
                        estado_rx <= ST_RX_STORE;
                    end
                end

                ST_RX_STORE: begin
                    rx_data = io_245;      // Almaceno dato recibido desde FTDI
                    rx_ftdi_flag <= 1'b1;  // Termine la lectura
                    rx_valid <= 1'b1
                    estado_rx <= ST_RX_CONFIRM;
                end

                ST_RX_CONFIRM: begin
                    // el top module leyo el dato?
                    if(rx_ready_reg == 1'b1) begin
                        rx_valid <= 1'b0; 
                        estado_rx <= ST_RX_FREE;  
                    end
                end

                ST_RX_FREE: begin
                    if(rx_ready_reg == 1'b0) begin
                        estado_rx <= ST_RX_IDLE;
                    end
                end

                default: estado_rx <= ST_RX_IDLE;

            endcase

            /* ---------- Maquina de estados TX ---------- */
            case (estado_tx)

                ST_TX_IDLE: begin
                    // Si estoy ocioso indago si hay algo para transmitir en Mercurial y si lo puedo enviar
                    if (tx_valid_reg && !tx_available_reg) begin
                        oe = 1'b1;              // Aseguro escritura del bus
                        tx_ftdi_flag <= 1'b1;
                        estado_tx <= ST_TX_STORE;
                    end
                end

                ST_TX_STORE: begin
                    tx_data_in <= tx_data;
                    tx_ready <= 1'b1;
                    estado_tx <= ST_TX_READY;
                end

                // TODO: Ver si se puede quitar este estado y mover el flag al estado anterior
                ST_TX_READY: begin
                    tx_ftdi_flag <= 1'b0;
                    estado_tx <= ST_TX_CONFIRM;
                end

                ST_TX_CONFIRM: begin
                    tx_ready     <= 1'b0;
                    tx_ftdi_flag <= 1'b1;
                    estado_tx    <= ST_TX_FREE;
                end

                ST_TX_FREE: begin
                    if (!tx_valid_reg)
                        estado_tx <= ST_TX_IDLE;
                end
            endcase
        end
    end    
endmodule