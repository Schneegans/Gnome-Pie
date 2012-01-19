#!/bin/bash

# Searches trough all vala files of Gnome-Pie and generates
# a gnomepie.pot for strings which need to be translated.

domain="gnomepie"
version="0.4"
copyright="Simon Schneegans <code@simonschneegans.de>"

filelist=$( find ../ui/ -name '*.ui' -printf "%h/%f " )
xgettext --package-name $domain \
         --package-version $version \
         --default-domain $domain \
         --output $domain.pot.tmp \
         --copyright-holder="$copyright" \
         -k_ \
         -L Glade \
         $filelist

filelist=$( find ../../src/ -name '*.vala' -printf "%h/%f " )         
xgettext --package-name $domain \
         --package-version $version \
         --default-domain $domain \
         --output $domain.pot \
         --copyright-holder="$copyright" \
         -k_ \
         -L C# \
         $filelist
         
awk 'NR>18' $domain.pot.tmp >> $domain.pot

sed --in-place $domain.pot --expression='s/CHARSET/UTF-8/'      

rm $domain.pot.tmp
