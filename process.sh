#!/bin/bash

rm -fR manuscript/*

for i in src/*.mau;
do
    chapter=$(basename ${i/.mau/} | sed -r -e s,"^[0-9]+_",, -e s,"_"," ",g)
    output=manuscript/$(basename ${i/.mau/.md})
    mau -i ${i} -o ${output} -f markua --verbose
    sed -i 1s/^/"# ${chapter}\n\n"/ ${output}
    sed -i s,"/images/pycabook/","images/", ${output}
done

ls -1 manuscript/*.md | xargs -n1 basename > manuscript/Book.txt

mkdir manuscript/resources
cp -R images manuscript/resources
