#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/ollama
mkdir -p ${BUILD_DIR}

cp -r /usr $BUILD_DIR
cp -r /bin $BUILD_DIR

apt update
apt install -y patchelf

SNAP=/snap/openwebui/current
mkdir -p $SNAP
ln -s $BUILD_DIR $SNAP/ollama

ldd $BUILD_DIR/bin/ollama

LD=$(echo $SNAP/ollama/usr/lib/*/ld-*.so*)
LIBS=$LIBS:$(echo $SNAP/ollama/usr/lib/*linux*/)

echo $LD
echo $LIBS
patchelf --set-interpreter $LD $BUILD_DIR/bin/ollama
patchelf --set-rpath $LIBS $BUILD_DIR/bin/ollama
$BUILD_DIR/bin/ollama --version
