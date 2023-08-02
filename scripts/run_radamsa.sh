#!/bin/bash

count=0
id=$1
seeds=$2
bin=$3
PROB=5
MAXX=10000

while true
do   
        for filename in ../input/*; do
                rand=$(( $RANDOM % 10 ))
                if (( $(echo "$rand < $PROB |bc -l") ))
                then
                        let "count+=1"
                        name=$(echo "$filename" | sed 's/^..\/input\///')
                        $bin "$filename" > "$name"-"$id"-"$count"

                        if (( count == MAXX ))
                        then
                                break
                        fi
                fi
        done
        echo "sleep for 3600s to avoid explosion"
        sleep 3600
done

		
