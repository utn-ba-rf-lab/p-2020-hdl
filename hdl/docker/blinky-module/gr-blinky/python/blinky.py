#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
# Copyright 2020 <+YOU OR YOUR COMPANY+>.
# 
# This is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
# 
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this software; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street,
# Boston, MA 02110-1301, USA.
# 
import numpy as np
import subprocess
import shlex
import serial
from gnuradio import gr

class blinky(gr.sync_block):
    """
    docstring for block blinky
    """
    def __init__(self,  estado):
        gr.sync_block.__init__(self,
            name="blinky",
            in_sig= [np.float32],
            out_sig=None)
        print("Configurando puerto USB\n")
        self.tty = serial.Serial('/dev/ttyUSB1', 115200, PARITY_NONE, STOPBITS_ONE) # linea agregada por Lucas



    def work(self, input_items, output_items):
        in0 = input_items[0]
        # <+signal processing here+>
	print("entra al work")
        if(in0==1):
            print("todos unos")
            b= np.uint8(0b11111111)
        else:
            print("todos ceros")
            b= np.uint8(0b00000000)

        self.tty.write(b.tobytes())

        return len(input_items[0])

