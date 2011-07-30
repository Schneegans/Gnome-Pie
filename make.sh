#!/bin/sh

mkdir build

cd build; cmake ..; make && ( cd ..; ./gnome-pie )
