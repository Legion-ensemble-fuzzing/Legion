#!/bin/bash

export INSTRUMENT_BIN=/home/threedean/FuzzingTools/Legion/bin/
export LEGION_PATH=/home/threedean/FuzzingTools/Legion

build() {

	SRC=${2%%.*}

	mkdir build
	rm -rf code_instrument/"$SRC"
	mkdir code_instrument
	cp "$2" code_instrument/"$2"
	pushd code_instrument || exit

	if [[ "$1" == "-zip" ]]; then
		unzip "$2"
	elif [[ "$1" == "-gz" ]]; then
		tar -xvf "$2"
	else
		echo "[LEGION]unknown compress format"
		exit 1
	fi

	rm "$2"

	export CC="clang"
	export CXX="clang++"
	export LD="clang"

	# we add fuzzer fsanitizer options for persistent fuzzing  $INSTRUMENT_BIN/trace.o
	export FSANITIZE_FUZZER_FLAGS="-fno-omit-frame-pointer -g -fsanitize-coverage=trace-pc-guard"
	export CFLAGS="$FSANITIZE_FUZZER_FLAGS"
	export CXXFLAGS="$FSANITIZE_FUZZER_FLAGS"

	#export EXTRALIBS="-L$INSTRUMENT_BIN $INSTRUMENT_BIN/entry.o $INSTRUMENT_BIN/trace.o"
	export EXTRALIBS="-L. -linstrumentor"

	pushd "$SRC" || exit
	cp $INSTRUMENT_BIN/libinstrumentor.a ./

	sed -i '/make/ s/make/bear make/' ./fuzzbuild
	./fuzzbuild

	if [[ "$3" == "--call-graph" ]]; then
		analyze
	fi

	popd || exit
	popd || exit
	cp -p code_instrument/$SRC/app build/instrumentapp

}

run(){
    folder_path=$1
	report_path=$2

	time ./build/instrumentapp "$folder_path" "$report_path"

	echo "[LEGION] finishe evaluating for this round!" 
}

analyze() {
	echo "[LEGION]generate call graph"
	cp $LEGION_PATH/doxygen.config ./
	doxygen doxygen.config
	pushd html || exit
	file=$(find . -type f -name "target*_cgraph.dot")
	cp "$file" ../../../build/cgraph.dot
	popd || exit
}

usage(){
	prog="$(basename "$0")"
	log-error "$prog No options given, don't know what to do\n"
}

[[ "$0" == 0 ]] && usage

if [[ "$1" == "build" ]]; then
	echo "[LEGION]AFL++ build"
	build "${@:2}"
elif [[ "$1" == "run" ]]; then
	echo "[LEGION]AFL++ running"
	run "${@:2}"
fi
