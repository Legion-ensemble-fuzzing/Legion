#!/bin/bash

build() {

	SRC=${2%%.*}

	rm -rf code_lib/$SRC
	mkdir code_lib
	cp $2 code_lib/$2
	pushd code_lib || exit

	if [[ "$1" == "-zip" ]]; then
		unzip "$2"
	elif [[ "$1" == "-gz" ]]; then
		tar -xvf "$2"
	else
		echo "[LEGION]unknown compress format"
		exit 1
	fi

	rm $2

	export CC="clang"
	export CXX="clang++"
	export LD="clang"

	# for honggfuzz we need to add sanitizers into flags
	export FSANITIZE_FUZZER_FLAGS="-fno-omit-frame-pointer -g -fsanitize=fuzzer,address,undefined"
	export CFLAGS=$FSANITIZE_FUZZER_FLAGS
	export CXXFLAGS=$FSANITIZE_FUZZER_FLAGS

	export EXTRALIBS=""

	pushd $SRC || exit
	./fuzzbuild
	popd || exit
	popd || exit
	cp -p code_lib/"$SRC"/app build/libapp
}

run() {
	rm -rf run_lib
	mkdir run_lib
	#mkdir run_lib/input
	mkdir run_lib/output
	#get initial seeds, if any, to input
	cp -r initial/* run_lib/output
	pushd run_lib || exit

	time=$1
	threads=$2

	if [ "$4" == "-d" ]; then
		dict="-dict=../dict.dict"
		echo "[LEGION]we use a dictionary from $dict!"
	fi

	
	#let's fxxking fuzz!
	timeout "$time" ../build/libapp -fork="$threads" -ignore_crashes=1 $dict ./output/ &


	popd || exit
	
	i=0
	counter=0
	outfolder=$3

	rm -rf "$outfolder"
	mkdir -p "$outfolder"
	while [ "$i" -lt "$time" ] 
		do
		echo "[LEGION-fuzzer]running LibFuzzer background, $i/$time seconds passed"
		sleep 60
		i=$(("$i" + 60))
		counter=$(("$counter" + 60))
		if [ "$counter" -eq 600 ]; then
			echo "[LEGION]copying files preodically to speed up the process"
			find "$outfolder" -type f -name '*' -print0 | xargs -0 rm -f
			find run_lib/output/ -type f -name '*' -print0 | xargs -0 cp --target-directory="$outfolder"
			#cp -r run_lib/output/* "$outfolder"
			counter=0
		fi
	done


	echo "[LEGION]libfuzzer run finished in $time seconds with $threads threads"

	#cp -r run_lib/output/* "$outfolder"
	find run_lib/output/ -type f -name '*' -print0 | xargs -0 cp --target-directory="$outfolder"
}

update_seed() {
	source=$1
	#cp "$source"/* run_lib/output
	find "$source" -type f -name '*' -print0 | xargs -0 cp --target-directory=run_lib/output/
}

usage(){
	#prog="$(basename "$0")"
	#log-error "$prog No options given, don't know what to do\n"
	echo "[LEGION]USAGE: LIBFUZZER.sh build -zip|-gz <file> or LIBFUZZER.sh run <time> <threads> <output folder> [-d]"
}

if [[ "$#" -lt 1 ]]; then
	usage
	exit 1
fi


if [[ "$1" == "build" ]]; then
	echo "[LEGION]LibFuzzer build"
	build "${@:2}"
elif [[ "$1" == "run" ]]; then
	echo "[LEGION]LibFuzzer running"
	run "${@:2}"
elif [[ "$1" == "update" ]]; then
	echo "[LEGION]LibFuzzer updating seeds"
	update_seed "${@:2}"
else
	usage
	exit 1
fi
