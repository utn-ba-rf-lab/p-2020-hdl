FROM debian:stretch

RUN mkdir /build && apt-get update && \
	apt-get install -y build-essential clang clang-format bison flex \
	libreadline-dev gawk tcl-dev libffi-dev git mercurial graphviz \
	xdot pkg-config python python3 libftdi-dev \
	qt5-default python3-dev libboost-all-dev cmake

RUN git clone https://github.com/cliffordwolf/icestorm.git /build/icestorm
RUN git clone https://github.com/YosysHQ/nextpnr.git /build/nextpnr
RUN git clone https://github.com/YosysHQ/arachne-pnr.git /build/arachne-pnr
RUN git clone https://github.com/YosysHQ/yosys.git /build/yosis

RUN apt-get install -y libboost-dev libboost-filesystem-dev libboost-thread-dev libboost-program-options-dev libboost-python-dev libboost-dev libeigen3-dev qt5-default clang-format 

RUN cd /build/icestorm && make -j$(nproc) && make install
RUN cd /build/nextpnr && cmake -DARCH=ice40 . && make -j$(nproc) && make install
RUN cd /build/arachne-pnr && make -j$(nproc) && make install
RUN cd /build/yosis && make -j$(nproc) && make install

RUN rm -rf /build/