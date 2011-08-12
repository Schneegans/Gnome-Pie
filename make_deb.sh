#!/bin/sh

mkdir build

cd build; cmake -DCMAKE_INSTALL_PREFIX=../debian/tmp/usr ..; make install && cd ..;

mkdir debian/tmp/DEBIAN

cp debian/control debian/tmp/DEBIAN/control

dpkg -b "debian/tmp" 

rm -r debian/tmp 

mv debian/tmp.deb gnome-pie.deb
