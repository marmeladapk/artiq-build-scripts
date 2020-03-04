#!/bin/bash

#TODO
# Make a enviroment restore
# If modified package is not used do not query git

orig_pwd=`pwd`

while [ x != "x$1" ] ; do
  if [ "$1" == "--without-sawg" ]; then
    without_sawg="--without-sawg"
  elif [ "$1" == "--note" ]; then
    note=$2
    shift
  elif [ "$1" == "-V" ]; then
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
    if [ -f $2 ]; then
      json_file=$2
    else
      echo "Provide file for kasli generic"
      exit 1
    fi
    shift
  elif [ "$1" == "metlino" ]; then
    board="metlino"
  elif [ "$1" == "--no-compile-gateware" ]; then
    no_gateware="--no-compile-gateware"
  fi
  shift
done

if [ -z ${board+x} ]; then
  echo "Which board? (amc rtm metlino kasli kasli_generic)"
  exit 1
fi
if [ "$board" == "kasli_generic" ]; then
  board_dir="kasli"
else
  board_dir=$board
fi
mkdir -p $board_dir

if [ "$board" == "kasli_generic" ]; then
  variant=`cat $json_file | python3 -c "import sys, json; print(json.load(sys.stdin)['variant'])"`
  hwrev=`cat $json_file | python3 -c "import sys, json; print(json.load(sys.stdin)['hw_rev'])"`
fi

if [ -z ${variant+x} ]; then
  if [ "$board" == "sayma_amc" ]; then
    variant="satellite"
  elif [ "$board" == "sayma_rtm" ]; then
    variant="satellite"
  elif [ "$board" == "kasli" ]; then
    variant="tester"
  elif [ "$board" == "metlino" ]; then
    variant="master"
  fi
fi
if [ -z ${hwrev+x} ]; then
  if [ "$board" == "sayma_amc" ]; then
    hwrev="v2.0"
  elif [ "$board" == "sayma_rtm" ]; then
    hwrev="v2.0"
  elif [ "$board" == "kasli" ]; then
    hwrev="v1.1"
  elif [ "$board" == "metlino" ]; then
    hwrev="v1.0"
  fi
fi

#Get complete environment state
artiq_dir=`python -c "import artiq; import os; print(os.path.dirname(artiq.__file__))"`
cd $artiq_dir
artiq_hash=`git rev-parse --short HEAD`
artiq_diff=`git diff`

misoc_dir=`python -c "import misoc; import os; print(os.path.dirname(misoc.__file__))"`
cd $misoc_dir
misoc_hash=`git rev-parse --short HEAD`
misoc_diff=`git diff`

migen_dir=`python -c "import migen; import os; print(os.path.dirname(migen.__file__))"`
cd $migen_dir
migen_hash=`git rev-parse --short HEAD`
migen_diff=`git diff`

nixscripts_dir="/home/pawel/artiq-dev/nix-scripts"
cd $nixscripts_dir
nixscripts_hash=`git rev-parse --short HEAD`
nixscripts_diff=`git diff`

vivado_ver=`vivado -version`

nix_pkgs_ver=`nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version'`

cd $orig_pwd

name=`date +"%Y-%m-%d_%H_%M_%S"`

if [ -z ${note+x} ]; then
  name+="_${board}_${variant}_${hwrev}"
else
  name+="_${board}_${variant}_${hwrev}_${note}"
fi

# echo $name

mkdir $board_dir/$name

cd $board_dir/$name

echo -e "Build:\n$board $variant $hwrev $without_sawg $no_gateware" >> environment.txt
if ! [ -z ${note+x} ]; then
  echo -e "Note: $note" >> environment.txt
fi
echo -e "Artiq:\n$artiq_hash\n" >> environment.txt
echo "$artiq_diff" > artiq.patch
echo -e "Misoc:\n$misoc_hash\n" >> environment.txt
echo "$misoc_diff" > misoc.patch
echo -e "Migen:\n$migen_hash\n" >> environment.txt
echo "$migen_diff" > migen.patch
echo -e "Nix scripts:\n$nixscripts_hash\n" >> environment.txt
echo "$nixscripts_diff" > nix_scripts.patch
echo -e "Vivado:\n$vivado_ver\n" >> environment.txt
echo -e "Nix:\n$nix_pkgs_ver\n" >> environment.txt
echo -e "Command:\n" >> environment.txt
echo `cat /home/pawel/artiq-dev/start_nix_shell.sh` >> environment.txt

if ! [ -z ${no_gateware+x} ]; then
    mkdir -p $variant
    cd $variant
    link="../../../${board}_${variant}_${hwrev}_latest"
    latest=`readlink $link`
    ln -s $latest/$variant/gateware gateware
    cd ..
fi

call=" -m artiq.gateware.targets.$board --output-dir=. $no_gateware $without_sawg"
if [ "$board" == "kasli_generic" ]; then
  call+=" $orig_pwd/$json_file"
  cp $orig_pwd/$json_file .
fi
if ! [[ "$board" == "sayma_rtm" || "$board" == "metlino" || "$board" == "kasli_generic" ]]; then
  call+=" -V $variant"
fi
if ! [ "$board" == "metlino" ]; then
  call+=" --hw-rev $hwrev"
fi
 
# echo $call
python $call |& tee build_log.txt

linkname="${board}_${variant}_${hwrev}_latest"
# echo $linkname

if [ -f "$variant/gateware/top.bit" ] || [ -f "gateware/top.bit" ]; then
  rm -f "../../$linkname"
  ln -sf `pwd` "../../$linkname"
else
  echo "Build failed, not updating $linkname link."
fi
cd $orig_pwd

