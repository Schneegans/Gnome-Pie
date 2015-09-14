#!/bin/bash

# get directory of script and cd to it
DIR="$( cd "$( dirname "$0" )" && pwd )"
cd $DIR

# Searches trough all vala files of Gnome-Pie and generates
# a gnomepie.pot for strings which need to be translated.

domain="gnomepie"
version="0.4"
copyright="Simon Schneegans <code@simonschneegans.de>"

rm $domain.pot

filelist=$( find ../ui/ -name '*.ui' -printf "%h/%f " )
xgettext --package-name $domain \
         --package-version $version \
         --default-domain $domain \
         --output $domain.pot \
         --copyright-holder="$copyright" \
         --from-code utf-8 \
         -k_ \
         -L Glade \
         $filelist

filelist=$( find ../../src/ -name '*.vala' -printf "%h/%f " )
xgettext --package-name $domain \
         --package-version $version \
         --default-domain $domain \
         --output $domain.pot \
         --copyright-holder="$copyright" \
         --from-code utf-8 \
         --join-existing \
         -k_ \
         -L C# \
         $filelist

sed --in-place $domain.pot --expression='s/CHARSET/UTF-8/'
