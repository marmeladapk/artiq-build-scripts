#!/bin/bash

# Add support to partial flashes and other goodies of artiq_flash

orig_pwd=`pwd`

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
  fi
  shift
done

if [ -z ${board+x} ]; then
  echo "Which board? (amc kasli)"
  exit 1
fi
if [ -z ${variant+x} ]; then
  if [ "$board" == "sayma_amc" ]; then
    variant="satellite"
  elif [ "$board" == "kasli" ]; then
    variant="opticlock"
  fi
fi
if [ -z ${hwrev+x} ]; then
  if [ "$board" == "sayma_amc" ]; then
    hwrev="v2.0"
  elif [ "$board" == "kasli" ]; then
    hwrev="v1.1"
  fi
fi

linkname="${board}_${variant}_${hwrev}_latest"
cd $linkname

if [ "$board" == "sayma_amc" ]; then
    board="sayma"
    if ! [ -f "rtm" ]; then
        link="../sayma_rtm_satellite_${hwrev}_latest"
        latest=`readlink $link`
        ln -s $latest rtm
    fi
fi
artiq_flash -t $board --srcbuild -d . -V $variant

cd $orig_pwd