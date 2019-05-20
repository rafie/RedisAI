#!/usr/bin/env bash

set -xe

ROOT=../..

if [[ "$1" == "cpu" ]]; then
	GPU=no
elif [[ "$1" == "gpu" ]]; then
	GPU=yes
else
	GPU=${GPU:-no}
fi

OS=$(python3 $ROOT/deps/readies/bin/platform --os)
ARCH=$(python3 $ROOT/deps/readies/bin/platform --arch)

PT_VERSION=1.0.1
#PT_VERSION="latest"

if [[ $OS == linux ]]; then
	PT_OS=shared-with-deps
	if [[ $GPU == no ]]; then
		PT_BUILD=cpu
	else
		PT_BUILD=cu90
	fi
	if [[ $ARCH == x64 ]]; then
		PT_ARCH=x86_64
	fi
elif [[ $OS == macosx ]]; then
	PT_OS=macos
	PT_BUILD=cpu
fi

[[ "$PT_VERSION" == "latest" ]] && PT_BUILD=nightly/${PT_BUILD}

LIBTORCH_ARCHIVE=libtorch-${PT_OS}-${PT_VERSION}.zip
[[ -z $LIBTORCH_URL ]] && LIBTORCH_URL=https://download.pytorch.org/libtorch/$PT_BUILD/$LIBTORCH_ARCHIVE

if [ ! -f $LIBTORCH_ARCHIVE ]; then
	echo "Downloading libtorch ${PT_VERSION} ${PT_BUILD}"
	wget $LIBTORCH_URL
fi

if [[ $OS == linux ]]; then
	PT_OS=linux
fi

unzip -o ${LIBTORCH_ARCHIVE}
tar czf libtorch-${PT_BUILD}-${PT_OS}-${PT_ARCH}-${PT_VERSION}.tar.gz libtorch/
rm -rf libtorch/ ${LIBTORCH_ARCHIVE}
