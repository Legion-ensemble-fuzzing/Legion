#!/bin/bash

if [ "$1" = "copy" ]; then
    unzip "$2" -d seeds/
    cp ./seeds/*/* "$3"
    rm -rf seeds
elif [ "$1" == "create" ]; then
    head /dev/urandom |  head -c 16 > "$3"/seed
else
    rm ./"$3"/*
    cp ./"$2"/* ./"$3"
fi