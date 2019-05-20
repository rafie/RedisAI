#!/bin/bash

REDISAI=$(realpath $1)
BINDIR=`cat BINDIR`

if (( $(./deps/readies/bin/platform --os) == macosx )); then
	export PATH=$PATH:$HOME/Library/Python/2.7/bin

	realpath() {
    	[[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
	}
fi

if ! command -v redis-server > /dev/null; then
	echo Cannot find redis-server. Aborting.
	exit 1
fi 

export LD_LIBRARY_PATH=$PWD/deps/install:${LD_LIBRARY_PATH}
ramp pack -m ramp.yml -o "build/redisai.{os}-{architecture}.latest.zip" $REDISAI
tar -C deps/install pczf $BINDIR/redisai-dependencies.tgz  *.so* 
