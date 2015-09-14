#!/bin/bash

# get directory of script and cd to it
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

echo "Insert the locale which you want to update:";
read locale;

if [ "$locale" == "" ]
then
    echo "No locale inserted! Aborting...";
    exit 1
fi

msgmerge -U $locale/LC_MESSAGES/$locale.po gnomepie.pot
