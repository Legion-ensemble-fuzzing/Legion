#!/bin/bash

count=0
id=$1
seeds=$2
bin=$3


while true
do
        let "count+=1"   
        for filename in ../input/*; do
                name=$(echo $filename | sed 's/^..\/input\///')
                $bin $filename > "$name"-"$id"-"$count"
        done
        echo "sleep for 600s to avoid explosion"
        sleep 600
done

		
