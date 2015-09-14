#!/bin/bash

# get directory of script and cd to it
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

echo "Insert your locale:";
read locale;

if [ "$locale" == "" ]
then
    echo "No locale inserted! Aborting...";
    exit 1
fi

mkdir -p $locale/LC_MESSAGES
msginit --locale=$locale --input=gnomepie.pot --output=$locale/LC_MESSAGES/$locale.po
