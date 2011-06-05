#!/bin/sh

mkdir build
cd build; make && ( cd ..; ./gnome-pie )
