#!/usr/bin/env python2
# -*- coding: utf-8 -*-
##################################################
# GNU Radio Python Flow Graph
# Title: Top Block
# Generated: Thu Dec  3 20:35:17 2020
##################################################

if __name__ == '__main__':
    import ctypes
    import sys
    if sys.platform.startswith('linux'):
        try:
            x11 = ctypes.cdll.LoadLibrary('libX11.so')
            x11.XInitThreads()
        except:
            print "Warning: failed to XInitThreads()"

from gnuradio import analog
from gnuradio import blocks
from gnuradio import eng_notation
from gnuradio import gr
from gnuradio.eng_option import eng_option
from gnuradio.filter import firdes
from gnuradio.wxgui import forms
from grc_gnuradio import wxgui as grc_wxgui
from optparse import OptionParser
import blinky
import wx


class top_block(grc_wxgui.top_block_gui):

    def __init__(self):
        grc_wxgui.top_block_gui.__init__(self, title="Top Block")

        ##################################################
        # Variables
        ##################################################
        self.samp_rate = samp_rate = 115200
        self.estado = estado = 0

        ##################################################
        # Blocks
        ##################################################
        self._estado_chooser = forms.button(
        	parent=self.GetWin(),
        	value=self.estado,
        	callback=self.set_estado,
        	label='estado',
        	choices=[0, 1],
        	labels=[],
        )
        self.Add(self._estado_chooser)
        self.blocks_throttle_0 = blocks.throttle(gr.sizeof_int*1, samp_rate,True)
        self.blocks_null_sink_0 = blocks.null_sink(gr.sizeof_int*1)
        self.blinky_blinky_0 = blinky.blinky()
        self.analog_const_source_x_0 = analog.sig_source_i(0, analog.GR_CONST_WAVE, 0, 0, estado)

        ##################################################
        # Connections
        ##################################################
        self.connect((self.analog_const_source_x_0, 0), (self.blocks_throttle_0, 0))    
        self.connect((self.blinky_blinky_0, 0), (self.blocks_null_sink_0, 0))    
        self.connect((self.blocks_throttle_0, 0), (self.blinky_blinky_0, 0))    

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.blocks_throttle_0.set_sample_rate(self.samp_rate)

    def get_estado(self):
        return self.estado

    def set_estado(self, estado):
        self.estado = estado
        self._estado_chooser.set_value(self.estado)
        self.analog_const_source_x_0.set_offset(self.estado)


def main(top_block_cls=top_block, options=None):

    tb = top_block_cls()
    tb.Start(True)
    tb.Wait()


if __name__ == '__main__':
    main()
