#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/openwebui
SNAP=/snap/openwebui/current
mkdir -p $SNAP
ln -s ${BUILD_DIR} $SNAP/openwebui
ls -la $BUILD_DIR/usr/local/bin/python3
$BUILD_DIR/usr/local/bin/python3 --version
export PYTHONPATH="$BUILD_DIR/usr/local/lib/python3.11/site-packages:$BUILD_DIR/usr/local/lib/python3.11/lib-dynload"
export LD_LIBRARY_PATH=$(echo $BUILD_DIR/usr/lib/*linux*/)

apt update
apt install binutils

strings $BUILD_DIR/usr/local/lib/python3.11/lib-dynload/_ssl.cpython-311-*-linux-gnu.so  | grep PyMod

$BUILD_DIR/usr/local/bin/python3 -c "import ssl"
$BUILD_DIR/usr/local/bin/python3 -m uvicorn --version
