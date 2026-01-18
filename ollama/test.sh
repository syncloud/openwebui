#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/ollama

SNAP=/snap/openwebui/current
mkdir -p $SNAP
ln -s $BUILD_DIR $SNAP/ollama

$BUILD_DIR/bin/ollama --version
