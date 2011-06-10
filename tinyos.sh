#! /usr/bin/env bash
# Here we setup the environment
# variables needed by the tinyos 
# make system

echo "Setting up for TinyOS MSP430X Integration"
export TOSROOT=
export TOSDIR=
export MAKERULES=
export LOWPAN_ROOT=

TOSROOT="/home/a-linan/Dropbox/TinyOS-development/mm/msp430/tinyos-2.x/"
TOSDIR="$TOSROOT/tos"
CLASSPATH=$CLASSPATH:$TOSROOT/support/sdk/java/tinyos.jar
MAKERULES="$TOSROOT/support/make/Makerules"
 export PATH=/opt/msp430-z1/bin:$PATH
#export PATH=/opt/msp430-gcc-4.4.5/bin:$PATH

export TOSROOT
export TOSDIR
export CLASSPATH
export MAKERULES

