#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/openwebui
SNAP=/snap/openwebui/current
mkdir -p $SNAP
ln -s ${BUILD_DIR} $SNAP/openwebui
ls -la $BUILD_DIR/usr/local/bin/python3
$BUILD_DIR/usr/local/bin/python3 --version
