#!/bin/bash

orig_pwd=`pwd`
flash_commands=""

while [ x != "x$1" ] ; do
  if [ "$1" == "-V" ]; then
    variant=$2
    shift
  elif [ "$1" == "-hw-rev" ]; then
    hwrev=$2
    shift
  elif [ "$1" == "amc" ]; then
    board="sayma_amc"
  elif [ "$1" == "rtm" ]; then
    board="sayma_rtm"
  elif [ "$1" == "kasli" ]; then
    board="kasli"
  elif [ "$1" == "kasli_generic" ]; then
    board="kasli_generic"
  elif [ "$1" == "metlino" ]; then
    board="metlino"
  elif [ "$1" == "-H" ]; then
    remote="-H $2"
    shift
  elif [[ "$1" = "gateware" || "$1" = "rtm_gateware" || "$1" = "bootloader" || "$1" = "firmware" || "$1" = "load" || "$1" = "rtm_load" || "$1" = "erase" || "$1" = "start" ]]; then
    flash_commands+=" $1"
  fi
  shift
done

if [ -z ${board+x} ]; then
  echo "Which board? (amc metlino kasli kasli_generic)"
  exit 1
fi

if [ -z ${variant+x} ]; then
  if [ "$board" == "sayma_amc" ]; then
    variant="satellite"
  elif [ "$board" == "kasli" ]; then
    variant="tester"
  elif [ "$board" == "kasli_generic" ]; then
    echo "Which variant?"
    exit 1
  elif [ "$board" == "metlino" ]; then
    variant="master"
  fi
fi
if [ -z ${hwrev+x} ]; then
  if [ "$board" == "sayma_amc" ]; then
    hwrev="v2.0"
  elif [[ "$board" == "kasli" || "$board" == "kasli_generic" ]]; then
    hwrev="v1.1"
  elif [ "$board" == "metlino" ]; then
    hwrev="v1.0"
  fi
fi

linkname="${board}_${variant}_${hwrev}_latest"
cd $linkname

if [ "$board" == "sayma_amc" ]; then
    board="sayma"
    if ! [ -e "rtm" ]; then
        link="../../sayma_rtm_satellite_${hwrev}_latest"
        latest=`readlink $link`
        ln -s $latest rtm
    fi
fi

if [ "$board" == "kasli_generic" ]; then
  board="kasli"
fi

artiq_flash -t $board --srcbuild -d . -V $variant $remote $flash_commands

cd $orig_pwd
