#!/bin/sh
export VOLK_GENERIC=1
export GR_DONT_LOAD_PREFS=1
export srcdir=/home/rf-lab/PID/p-2020-hdl/hdl/docker/blinky-module/gr-blinky/python
export PATH=/home/rf-lab/PID/p-2020-hdl/hdl/docker/blinky-module/gr-blinky/build/python:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH
export PYTHONPATH=/home/rf-lab/PID/p-2020-hdl/hdl/docker/blinky-module/gr-blinky/build/swig:$PYTHONPATH
/usr/bin/python2 /home/rf-lab/PID/p-2020-hdl/hdl/docker/blinky-module/gr-blinky/python/qa_blinky.py 
