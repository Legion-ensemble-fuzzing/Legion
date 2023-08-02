#!/bin/bash

export RADAMSA_BIN=~/FuzzingTools/radamsa/bin/radamsa
export RADAMSA_SHL=~/FuzzingTools/Legion/scripts/run_radamsa.sh

build() {
	echo "[LEGION]for radamsa we do not need to build a binary"
}

run(){
	rm -rf run_radamsa
	mkdir run_radamsa
	mkdir run_radamsa/input
	mkdir run_radamsa/output
	#get initial seeds, if any, to in
	cp -r initial/* run_radamsa/input
	cp $RADAMSA_SHL ./run_radamsa/run_radamsa.sh
	pushd run_radamsa || exit
	pushd output || exit
	
	time=$1
	threads=$2

	#nohup bash -c '\
	i=0
	while [ $i -lt "$threads" ] 
	do
		i=$(("$i" + 1))
		timeout "$time" ../run_radamsa.sh $i ../input $RADAMSA_BIN &
	done

	popd || exit
	popd || exit

	#sleep "$time"
	i=0
	counter=0
	outfolder=$3

	rm -rf "$outfolder"
	mkdir -p "$outfolder"
	while [ "$i" -lt "$time" ] 
		do
		echo "[LEGION-fuzzer]running Radamsa background, $i/$time seconds passed"
		sleep 60
		i=$(("$i" + 60))
		counter=$(("$counter" + 60))
		if [ "$counter" -eq 600 ]; then
			echo "[LEGION]copying files preodically to speed up the process"
			find "$outfolder" -type f -name '*' -print0 | xargs -0 rm -f
			#cp -r run_radamsa/output/* "$outfolder"
			find run_radamsa/output -type f -name '*' -print0 | xargs -0 cp --target-directory="$outfolder"
			#rm run_radamsa/output/*
			rm -rf run_radamsa/output
			mkdir run_radamsa/output
			counter=0
		fi
	done


	echo "[LEGION]$threads instances of radamsa run finished in $time seconds"

	find run_radamsa/output -type f -name '*' -print0 | xargs -0 cp --target-directory="$outfolder"
	#cp -r run_radamsa/output/* "$outfolder"
}

update_seed() {
	source=$1
	find "$source" -type f -name '*' -print0 | xargs -0 cp --target-directory=run_radamsa/input
	#cp "$source"/* run_radamsa/input
}


usage(){
	#prog="$(basename "$0")"
	#log-error "$prog No options given, don't know what to do\n"
	echo "[LEGION]USAGE: RADAMSA.sh build -zip|-gz <file> or RADAMSA.sh run <time> <threads> <output folder> [-d]"
}

if [[ "$#" -lt 1 ]]; then
	usage
	exit 1
fi

if [[ "$1" == "build" ]]; then
	#echo "[LEGION]AFL++ build"
	build "${@:2}"
elif [[ "$1" == "run" ]]; then
	echo "[LEGION]radamsa running"
	run "${@:2}"
elif [[ "$1" == "update" ]]; then
	echo "[LEGION]radamsa updating seeds"
	update_seed "${@:2}"
else
	usage
	exit 1
fi
