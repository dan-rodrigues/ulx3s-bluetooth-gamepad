#!/bin/sh

set -eu

ULX3S_SIZE=85f
ULX3S_TTY=/dev/tty.usbserial-120001

fujprog esp32_passthru/ulx3s_${ULX3S_SIZE}.bit
cd unijoysticle2/firmware/
idf.py -p ${ULX3S_TTY} flash

cd ../..
make ulx3s_prog

