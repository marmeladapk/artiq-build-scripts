#!/bin/bash

# Add support to partial flashes and other goodies of artiq_flash
# Add support for kasli_generic

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
  elif [ "$1" == "kasli_generic" ]; then
    board="kasli_generic"
  elif [ "$1" == "metlino" ]; then
    board="metlino"
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
        link="../sayma_rtm_satellite_${hwrev}_latest"
        latest=`readlink $link`
        ln -s $latest rtm
    fi
fi

if [ "$board" == "kasli_generic" ]; then
  board="kasli"
fi

artiq_flash -t $board --srcbuild -d . -V $variant

cd $orig_pwd
