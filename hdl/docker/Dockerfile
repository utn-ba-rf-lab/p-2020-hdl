FROM debian:stretch

# dependencies for lattice toolchain
RUN mkdir /build && apt-get update && \
	apt-get install -y build-essential clang clang-format bison flex \
	libreadline-dev gawk tcl-dev libffi-dev git mercurial graphviz \
	xdot pkg-config python python3 libftdi-dev \
	qt5-default python3-dev libboost-all-dev cmake

# lattice toolchain
RUN git clone https://github.com/cliffordwolf/icestorm.git /build/icestorm
RUN git clone https://github.com/YosysHQ/nextpnr.git /build/nextpnr
RUN git clone https://github.com/YosysHQ/arachne-pnr.git /build/arachne-pnr
RUN git clone https://github.com/YosysHQ/yosys.git /build/yosis

# more dependencies for lattice toolchain
RUN apt-get install -y libboost-dev libboost-filesystem-dev libboost-thread-dev libboost-program-options-dev libboost-python-dev libboost-dev libeigen3-dev qt5-default clang-format 

# build and install lattice toolchain
RUN cd /build/icestorm && make -j$(nproc) && make install
RUN cd /build/nextpnr && cmake -DARCH=ice40 . && make -j$(nproc) && make install
RUN cd /build/arachne-pnr && make -j$(nproc) && make install
RUN cd /build/yosis && make -j$(nproc) && make install
RUN rm -rf /build/

# gnuradio installation
RUN apt install -y gnuradio
RUN apt install -y gr-osmosdr

# mercurial grc module dependencies
RUN apt update && apt-get install -y --no-install-recommends \
    python-pip && apt clean
RUN pip2 install pyserial numpy

# Mercurial module instalation
ARG REBUILD
#RUN echo ${REBUILD} && git clone https://github.com/sdr-tx/gnuradio-module module && \
#RUN mkdir module
COPY docker/gnuradio-module module
RUN cd module && rm -rf build && mkdir build && cd build && cmake .. && make install

# Agregado para NANO y MINICOM
RUN apt install -y minicom nano
RUN apt-get install x11-xserver-utils

