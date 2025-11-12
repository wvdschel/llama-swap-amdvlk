#!/bin/bash
set -eo pipefail

ldd /app/llama-server

NEEDED_LIBS=( $(ldd /app/llama-server | grep '=> /app' | sed -rE 's/[^>]+>\s+([^ ]+).*/\1/') )
for lib in $(ls /app/*.so*); do
    if ! [[ " ${NEEDED_LIBS[@]} " =~ " ${lib} " ]]; then
        echo "Removing unused library: $lib"
        rm -f "$lib"
    else
        echo "Retaining library: $lib"
    fi
done