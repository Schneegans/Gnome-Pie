#!/bin/bash

shopt -s globstar

text="/////////////////////////////////////////////////////////////////////////
// Copyright 2011-2018 Simon Schneegans
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// \"Software\"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
                    sed -e '1,22d' ${file} > /tmp/copyright_tmp && mv /tmp/copyright_tmp ${file}
                    echo "${text}" > /tmp/copyright_tmp
                    cat ${file} >> /tmp/copyright_tmp && mv /tmp/copyright_tmp ${file}
                fi
            fi
        done
    done
done



