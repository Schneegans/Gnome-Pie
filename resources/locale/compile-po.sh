#!/bin/bash

for d in `ls -d */`
do
    msgfmt -c -v $d/LC_MESSAGES/*.po -o $d/LC_MESSAGES/gnomepie.mo
done
