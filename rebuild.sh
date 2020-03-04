#!/bin/bash

artiq=0

while IFS="" read -r p || [ -n "$p" ]
do
  if [ "$p" == "Artiq:" ]; then
    read -r artiq_hash
  elif [ "$p" == "Misoc:" ]; then
    read -r misoc_hash
  elif [ "$p" == "Migen:" ]; then
    read -r migen_hash
  elif [ "$p" == "Nix scripts:" ]; then
    read -r nix_scripts_hash
  elif [ "$p" == "Nix:" ]; then
    read -r nix_hash
    nix_arr=(${nix_hash//./ })
  fi
done < environment.txt
nix_hash=${nix_arr[3]}
nix_hash=${nix_hash:0:11}

mkdir temp_build
cd temp_build

git clone https://github.com/m-labs/artiq.git
cd artiq
git checkout $artiq_hash
git apply ../../artiq.patch
cd ..

git clone https://github.com/m-labs/misoc.git
cd misoc
git checkout $misoc_hash
git apply ../../misoc.patch
cd ..

git clone https://github.com/m-labs/migen.git
cd migen
git checkout $migen_hash
git apply ../../migen.patch
cd ..

git clone https://git.m-labs.hk/M-Labs/nix-scripts.git
cd nix-scripts
git checkout $nix_scripts_hash
git apply ../../nix_scripts.patch
cd ..

NIX_PATH="nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/$nix_hash.tar.gz" nix-shell -I artiqSrc="`pwd`/artiq" ./nix-scripts/artiq-fast/shell-dev.nix
