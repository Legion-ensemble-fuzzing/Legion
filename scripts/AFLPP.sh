#!/bin/bash

export AFLPP_BIN=/home/threedean/FuzzingTools/AFLplusplus

build() {

	SRC=${2%%.*}

	rm -rf code_aflpp/"$SRC"
	mkdir code_aflpp
	cp "$2" code_aflpp/"$2"
	pushd code_aflpp || exit

	if [[ "$1" == "-zip" ]]; then
		unzip "$2"
	elif [[ "$1" == "-gz" ]]; then
		tar -xvf "$2"
	else
		echo "[LEGION]unknown compress format"
		exit 1
	fi

	rm "$2"

	export CC="$AFLPP_BIN/afl-clang-fast"
	export CXX="$AFLPP_BIN/afl-clang-fast++"
	export LD="$AFLPP_BIN/afl-clang-fast"

	# we use asan and ubsan by default
	export AFL_LLVM_LAF_ALL=1
	export AFL_USE_UBSAN=1
	export AFL_USE_ASAN=1

	# we add fuzzer fsanitizer options for persistent fuzzing
	export FSANITIZE_FUZZER_FLAGS="-fno-omit-frame-pointer -g -fsanitize=fuzzer"
	export CFLAGS="$FSANITIZE_FUZZER_FLAGS"
	export CXXFLAGS="$FSANITIZE_FUZZER_FLAGS"

	export EXTRALIBS=""

	pushd "$SRC" || exit
	./fuzzbuild
	popd || exit
	popd || exit
	cp -p code_aflpp/"$SRC"/app build/aflppapp

}

run(){
	#sudo $AFLPP_BIN/afl-system-config
	rm -rf run_aflpp
	mkdir run_aflpp
	mkdir run_aflpp/input
	mkdir run_aflpp/output
	#get initial seeds, if any, to in
	cp -r initial/* run_aflpp/input
	pushd run_aflpp || exit

	time=$1
	threads=$2

	#echo $1
	#echo $2

	if [ "$4" == "-d" ]; then
		dict="-x ../dict.dict"
	fi

	echo "[LEGION]$dict"

	# start the main fuzzing thread
	# screen -dmS afl-main timeout "$time" $AFLPP_BIN/afl-fuzz -i input -o output -M fuzzer0 $dict -- ../build/aflppapp @@
	timeout "$time" $AFLPP_BIN/afl-fuzz -i input -o output -M fuzzer0 $dict -- ../build/aflppapp @@ &

	# start other ones
	#nohup bash -c '\
	i=1
	while [ "$i" -lt "$threads" ]
       	do 
		#screen -dmS afl-"$i" timeout "$time" $AFLPP_BIN/afl-fuzz -i input -o output -S fuzzer$i $dict -- ../build/aflppapp @@
		timeout "$time" $AFLPP_BIN/afl-fuzz -i input -o output -S fuzzer$i $dict -- ../build/aflppapp @@ &
	i=$(("$i" + 1))
	done

	# channel output of a sceen to current terminal without blocking it

	popd || exit

	echo "[LEGION]sleep $time seconds before fuzzing round finish"

	#sleep "$time"
	i=0
	counter=0
	outfolder=$3

	rm -rf "$outfolder"
	mkdir -p "$outfolder"
	while [ "$i" -lt "$time" ] 
		do
		echo "[LEGION-fuzzer]running AFL++ background, $i/$time seconds passed"
		sleep 60
		i=$(("$i" + 60))
		counter=$(("$counter" + 60))
		if [ "$counter" -eq 600 ]; then
			echo "[LEGION]copying files preodically to speed up the process"
			find "$outfolder" -type f -name '*' -print0 | xargs -0 rm -f
			find run_aflpp/output/fuzzer0/queue -type f -name '*' -print0 | xargs -0 cp --target-directory="$outfolder"
			#for dir in run_aflpp/output/fuzzer*/queue; do
			#	find "$dir" -type f -exec cp {} "$outfolder" \;
			#	#cp -r "$dir"/* "$outfolder"
			#done
			counter=0
		fi
	done

	echo "[LEGION]$threads instances of AFLPlusPlus run finished in $time seconds"

	#find run_aflpp/output/fuzzer0/queue -type f -name '*' -print0 | xargs -0 cp --target-directory="$outfolder"
		

	for dir in run_aflpp/output/fuzzer*/queue; do
		#cp -r "$dir"/* "$outfolder"
		find "$dir" -type f -name '*' -print0 | xargs -0 cp --target-directory="$outfolder"
		#find "$dir" -type f -exec cp {} "$outfolder" \;
	done
}

update_seed() {
	source=$1
	for dir in run_aflpp/output/fuzzer*/queue; do
		#cp -r "$source"/* "$dir"
		#find "$source" -type f -exec cp {} "$dir" \;
		find "$source" -type f -name '*' -print0 | xargs -0 cp --target-directory="$dir"
	done
}

# we use afl++ for potential seed minimization
minimize() {
	# this is used since the minimization seem to crash or timeout when evaluating real tools
	export AFL_SKIP_BIN_CHECK=1
	in_dir=$1
	out_dir=$2
	#command="$AFLPP_BIN/afl-cmin -i $in_dir -o $out_dir -- ./build/aflppapp @@"
	#echo $command
	time $AFLPP_BIN/afl-cmin -i "$in_dir" -o "$out_dir" -- ./build/aflppapp @@
	export AFL_SKIP_BIN_CHECK=
}


usage(){
	#prog="$(basename "$0")"
	#log-error "$prog No options given, don't know what to do\n"
	echo "[LEGION]USAGE: AFLPP.sh build -zip|-gz <file> or AFLPP.sh run <time> <threads> <output folder> [-d]"
}

if [[ "$#" -lt 1 ]]; then
	usage
	exit 1
fi

if [[ "$1" == "build" ]]; then
	echo "[LEGION]AFL++ build"
	build "${@:2}"
elif [[ "$1" == "run" ]]; then
	echo "[LEGION]AFL++ running"
	run "${@:2}"
elif [[ "$1" == "update" ]]; then
	echo "[LEGION]AFL++ updating seeds"
	update_seed "${@:2}"
elif [[ "$1" == "minimize" ]]; then
	echo "[LEGION]AFL++ minimizing seeds"
	minimize "${@:2}"
else
	usage
	exit 1
fi