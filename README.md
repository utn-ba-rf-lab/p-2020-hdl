# p-2020-hdl

Repositorio para el desarrollo de firmware de la placa p-2020-hdl del Proyecto de Investigación y Desarrollo "Diseño de modulador por amplitud de pulso y generador arbitrario de señales implementado sobre FPGA (2)"

Por consultas escribir a rf-lab@frba.utn.edu.ar

## Descripción de los archivos

    * build_image.sh
    
Para construir una imagen en docker del ambiente de trabajo ubuntu:20.04 

    * build_image_frba.sh
    
Idem anterior pero en la red de UTN-FRBA

    * run_in_docker.sh
    
Para correr la imagen del ambiente de trabajo, para luego desarrollar y programar la placa

### Build instructions

```
cd syn
make
make prog
```

