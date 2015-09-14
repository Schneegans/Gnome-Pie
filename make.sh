#!/bin/sh

# get directory of script and cd to it
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

./resources/locale/compile-po.sh

mkdir build

cd build; cmake ..; make -j8 && ( cd .. )
