#!/bin/bash

echo "Insert the locale which you want to update:";
read locale;

if [ "$locale" == "" ]
then
    echo "No locale inserted! Aborting...";
    exit 1
fi

msgmerge -U $locale/LC_MESSAGES/$locale.po gnomepie.pot
