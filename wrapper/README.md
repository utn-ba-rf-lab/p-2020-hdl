# PID
# Wrapper

<img src="https://github.com/utn-ba-rf-lab/p-2020-hdl/blob/main/wrapper/png/MachineState.png" alt="MachineState" width="600"/>

* **in_out_245 (entrada/salida)**       [7:0] FIFO lectura y escritura      

* **rxf_245 (salida)**                  1 = NO leer el FIFO.
                                        0 = Leer el FIFO llevando RD=0 Y luego poner RD=1 entonces RXF vuelve a 1 y solo sera 0 en caso de que haya otro byte para leer.

* **rx_245 (entrada)**                  1 = Deshabilita la lectura del FIFO.
                                        0 = Habilita la lectura del FIFO.

* **txe_245 (salida)**                  1 = NO escribir el FIFO.
                                        0 = Escribir el FIFO llevando WR=1 Y luego poner WR=1 

* **wr_245 (entrada)**                  1 = nada
                                        0 = Escribe la data en la salida 