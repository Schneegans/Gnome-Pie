#!/bin/bash

# Searches trough all vala files of Gnome-Pie and generates
# a gnomepie.pot for strings which need to be translated.

filelist=$( find ../../src/ -name '*.vala' -printf "%h/%f " )

domain="gnomepie"
version="0.2"
copyright="Simon Schneegans <code@simonschneegans.de>"

xgettext --package-name $domain \
         --package-version $version \
         --default-domain $domain \
         --output $domain.pot \
         --copyright-holder="$copyright" \
         -k_ \
         -L C# \
         $filelist

sed --in-place $domain.pot --expression='s/CHARSET/UTF-8/'      

