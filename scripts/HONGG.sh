#!/bin/bash

export HONGG_BIN=/home/threedean/FuzzingTools/honggfuzz

build() {

	SRC=${2%%.*}

	rm -rf code_hongg/$SRC
	mkdir code_hongg
	cp $2 code_hongg/$2
	pushd code_hongg || exit

	if [[ "$1" == "-zip" ]]; then
		unzip "$2"
	elif [[ "$1" == "-gz" ]]; then
		tar -xvf "$2"
	else
		echo "[LEGION]unknown compress format"
		exit 1
	fi

	rm "$2"

	export CC="$HONGG_BIN/hfuzz_cc/hfuzz-clang"
	export CXX="$HONGG_BIN/hfuzz_cc/hfuzz-clang++"
	export LD="$HONGG_BIN/hfuzz_cc/hfuzz-clang"

	# for honggfuzz we need to add sanitizers into flags
	export FSANITIZE_FUZZER_FLAGS="-fno-omit-frame-pointer -g -fsanitize=address,undefined"
	export CFLAGS=$FSANITIZE_FUZZER_FLAGS
	export CXXFLAGS=$FSANITIZE_FUZZER_FLAGS

	export EXTRALIBS=""

	pushd "$SRC" || exit
	./fuzzbuild
	popd || exit
	popd || exit
	cp code_hongg/"$SRC"/app build/honggapp
}

run() {
	rm -rf run_hongg
	mkdir run_hongg
	mkdir run_hongg/input
	mkdir run_hongg/output
	#get initial seeds, if any, to input
	cp -r initial/* run_hongg/input
	pushd run_hongg || exit

	# honggfuzz automatically run CPU/2 threads
	time=$1
	threads=$2


	if [ "$4" == "-d" ]; then
		dict="-w ../dict.dict"
		echo "[LEGION]we use a dictionary from $dict!"
	fi

	#let's fxxking fuzz!
	timeout "$time" $HONGG_BIN/honggfuzz --threads "$threads" -i input --output output $dict -- ../build/honggapp ___FILE___ &


	popd || exit
	#sleep "$time"
	i=0
	counter=0
	outfolder=$3

	rm -rf "$outfolder"
	mkdir -p "$outfolder"
	while [ "$i" -lt "$time" ] 
		do
		echo "[LEGION-fuzzer]running HonggFuzz background, $i/$time seconds passed"
		sleep 60
		i=$(("$i" + 60))
		counter=$(("$counter" + 60))
		if [ "$counter" -eq 600 ]; then
			echo "[LEGION]copying files preodically to speed up the process"
			find "$outfolder" -type f -name '*' -print0 | xargs -0 rm -f
			find run_hongg/ouput -type f -name '*' -print0 | xargs -0 cp --target-directory="$outfolder"
			#find run_hongg/output -type f -exec cp {} "$outfolder" \;
			#cp -r run_hongg/output/* "$outfolder"
			counter=0
		fi
	done

	#timeout 300 $HONGG_BIN/honggfuzz --threads 1 -i input --output output  -- ../build/honggapp ___FILE___

	
	
	echo "[LEGION]HonggFuzz run finished in $time seconds with $threads threads"

	#cp -r run_hongg/output/* "$outfolder"
	#find run_hongg/output -type f -exec cp {} "$outfolder" \;
	find run_hongg/ouput -type f -name '*' -print0 | xargs -0 cp --target-directory="$outfolder"

}

update_seeds() {
	sourcedir=$1
	#cp -r "$sourcedir"/* run_hongg/output
	#find "$sourcedir" -type f -exec cp {} run_hongg/output \;
	find "$sourcedir" -type f -name '*' -print0 | xargs -0 cp --target-directory=run_hongg/ouput
}

usage(){
	#prog="$(basename "$0")"
	#log-error "$prog No options given, don't know what to do\n"
	echo "[LEGION]USAGE: HONGG.sh build -zip|-gz <file> or HONGG.sh run <time> <threads> <output folder> [-d]"
}

if [[ "$#" -lt 1 ]]; then
	usage
	exit 1
fi

if [[ "$1" == "build" ]]; then
	echo "[LEGION]HONGGFUZZ build"
	build "${@:2}"
elif [[ "$1" == "run" ]]; then
	echo "[LEGION]HONGGFUZZ running"
	run "${@:2}"
elif [[ "$1" == "update" ]]; then
	echo "[LEGION]HONGGFUZZ updating seeds"
	update_seeds "${@:2}"
else
	usage
	exit 1
fi
