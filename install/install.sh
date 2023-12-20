#!/bin/bash

# Enleve dossier si existe déjà été installé
rm -r /etc/mercury &>/dev/null
rm -r /opt/mercury &>/dev/null

mkdir -p /etc/mercury/benchmarks
mkdir /opt/mercury
mkdir /opt/mercury/scripts
mkdir /opt/mercury/manifests

cp ../exec/linux/mercury /usr/sbin

mkdir /opt/mercury/scripts/lib
cp ../modules/lib/lib.sh /opt/mercury/scripts/lib

for module in ../modules/linux/*/
do

    mkdir /opt/mercury/scripts/$(basename $module)

    cp $module/scripts/* /opt/mercury/scripts/$(basename $module)/
    cp $module/manifest.json /opt/mercury/manifests/$(basename $module).json
    cp $module/*.toml /etc/mercury/benchmarks/
    
done 

