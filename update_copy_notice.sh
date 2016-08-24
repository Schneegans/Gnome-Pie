#!/bin/bash

shopt -s globstar

text="/////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011-2016 by Simon Schneegans
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
/////////////////////////////////////////////////////////////////////////"

types=(
    ".vala"
)

folders=(
    "src"
)

for folder in "${folders[@]}"
do
    for type in "${types[@]}"
    do
        for file in ${folder}/**/*${type}
        do
            if [ -f $file ]
            then
                if grep -q "Simon Schneegans" ${file}
                then
                    echo "Reformatting ${file} ..."
                    sed -e '1,16d' ${file} > /tmp/copyright_tmp && mv /tmp/copyright_tmp ${file}
                    echo "${text}" > /tmp/copyright_tmp
                    cat ${file} >> /tmp/copyright_tmp && mv /tmp/copyright_tmp ${file}
                fi
            fi
        done
    done
done



