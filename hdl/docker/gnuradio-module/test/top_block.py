#!/usr/bin/env python2
# -*- coding: utf-8 -*-
##################################################
# GNU Radio Python Flow Graph
# Title: Top Block
# Generated: Wed Nov 11 00:15:44 2020
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
import Mercurial_SDR
import wx


class top_block(grc_wxgui.top_block_gui):

    def __init__(self):
        grc_wxgui.top_block_gui.__init__(self, title="Top Block")

        ##################################################
        # Variables
        ##################################################
        self.variable_slider_3 = variable_slider_3 = 50e-3
        self.variable_slider_0 = variable_slider_0 = 5000
        self.samp_rate = samp_rate = 1000
        self.LedStateChooser = LedStateChooser = 0

        ##################################################
        # Blocks
        ##################################################
        self._LedStateChooser_chooser = forms.button(
        	parent=self.GetWin(),
        	value=self.LedStateChooser,
        	callback=self.set_LedStateChooser,
        	label='LedState',
        	choices=[0, 1],
        	labels=[],
        )
        self.Add(self._LedStateChooser_chooser)
        _variable_slider_3_sizer = wx.BoxSizer(wx.VERTICAL)
        self._variable_slider_3_text_box = forms.text_box(
        	parent=self.GetWin(),
        	sizer=_variable_slider_3_sizer,
        	value=self.variable_slider_3,
        	callback=self.set_variable_slider_3,
        	label='Gain',
        	converter=forms.float_converter(),
        	proportion=0,
        )
        self._variable_slider_3_slider = forms.slider(
        	parent=self.GetWin(),
        	sizer=_variable_slider_3_sizer,
        	value=self.variable_slider_3,
        	callback=self.set_variable_slider_3,
        	minimum=0,
        	maximum=1,
        	num_steps=10,
        	style=wx.SL_HORIZONTAL,
        	cast=float,
        	proportion=1,
        )
        self.Add(_variable_slider_3_sizer)
        _variable_slider_0_sizer = wx.BoxSizer(wx.VERTICAL)
        self._variable_slider_0_text_box = forms.text_box(
        	parent=self.GetWin(),
        	sizer=_variable_slider_0_sizer,
        	value=self.variable_slider_0,
        	callback=self.set_variable_slider_0,
        	label='Frequency',
        	converter=forms.float_converter(),
        	proportion=0,
        )
        self._variable_slider_0_slider = forms.slider(
        	parent=self.GetWin(),
        	sizer=_variable_slider_0_sizer,
        	value=self.variable_slider_0,
        	callback=self.set_variable_slider_0,
        	minimum=0,
        	maximum=400e3,
        	num_steps=1000,
        	style=wx.SL_HORIZONTAL,
        	cast=float,
        	proportion=1,
        )
        self.Add(_variable_slider_0_sizer)
        self.blocks_throttle_0 = blocks.throttle(gr.sizeof_float*1, samp_rate,True)
        self.blocks_null_source_0 = blocks.null_source(gr.sizeof_float*1)
        self.blocks_null_sink_0 = blocks.null_sink(gr.sizeof_float*1)
        self.analog_const_source_x_0 = analog.sig_source_f(0, analog.GR_CONST_WAVE, 0, 0, LedStateChooser)
        self.Mercurial_SDR_0 = Mercurial_SDR.Mercurial_SDR('am', '8psk', 468000, samp_rate, 'natural_key', 'linear_key', 100,7,'pll_201','pll_50.25','pll_201','pll_100.5',5000000,50000,50000)

        ##################################################
        # Connections
        ##################################################
        self.connect((self.Mercurial_SDR_0, 0), (self.blocks_null_sink_0, 0))    
        self.connect((self.analog_const_source_x_0, 0), (self.blocks_throttle_0, 0))    
        self.connect((self.blocks_null_source_0, 0), (self.Mercurial_SDR_0, 1))    
        self.connect((self.blocks_throttle_0, 0), (self.Mercurial_SDR_0, 0))    

    def get_variable_slider_3(self):
        return self.variable_slider_3

    def set_variable_slider_3(self, variable_slider_3):
        self.variable_slider_3 = variable_slider_3
        self._variable_slider_3_slider.set_value(self.variable_slider_3)
        self._variable_slider_3_text_box.set_value(self.variable_slider_3)

    def get_variable_slider_0(self):
        return self.variable_slider_0

    def set_variable_slider_0(self, variable_slider_0):
        self.variable_slider_0 = variable_slider_0
        self._variable_slider_0_slider.set_value(self.variable_slider_0)
        self._variable_slider_0_text_box.set_value(self.variable_slider_0)

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.blocks_throttle_0.set_sample_rate(self.samp_rate)

    def get_LedStateChooser(self):
        return self.LedStateChooser

    def set_LedStateChooser(self, LedStateChooser):
        self.LedStateChooser = LedStateChooser
        self._LedStateChooser_chooser.set_value(self.LedStateChooser)
        self.analog_const_source_x_0.set_offset(self.LedStateChooser)


def main(top_block_cls=top_block, options=None):

    tb = top_block_cls()
    tb.Start(True)
    tb.Wait()


if __name__ == '__main__':
    main()
