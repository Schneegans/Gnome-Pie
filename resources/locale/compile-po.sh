#!/bin/bash

for d in `ls -d */`
do
    echo -n "$d "
    msgfmt -c -v $d/LC_MESSAGES/*.po -o $d/LC_MESSAGES/gnomepie.mo
done
