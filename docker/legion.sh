#!/bin/bash

if [ "$#" -ne 3 ]; then
	echo "Illegal number of parameters"
	exit
fi

nohup ~/FuzzingTools/Legion/bin/legion --run --aflpp --hongg --libfuzzer --radamsa --qsym -m --resource $1 --round $2 --round-time $3 --initial seeds.zip | tee run.log
