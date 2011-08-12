#!/bin/sh

mkdir build

cd build

cmake -DCMAKE_INSTALL_PREFIX=../debian/tmp/usr ..

make install

cd ..

mkdir debian/tmp/DEBIAN

cp debian/control debian/tmp/DEBIAN/control


replace='s/ARCH_REPLACE/i368/'

# Figure out user's machine architecture and put it in the control file
MACHINE=`uname -m`
if [ "$MACHINE" = "x86_64" ]; then
    replace='s/ARCH_REPLACE/amd64/'
fi

sed --in-place debian/tmp/DEBIAN/control --expression=$replace

# build the package
fakeroot dpkg -b "debian/tmp" 

rm -r debian/tmp 

mv debian/tmp.deb gnome-pie.deb

