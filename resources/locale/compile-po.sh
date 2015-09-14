#!/bin/bash

# get directory of script and cd to it
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

for d in `ls -d */`
do
    echo -n "$d "
    msgfmt -c -v $d/LC_MESSAGES/*.po -o $d/LC_MESSAGES/gnomepie.mo
done
