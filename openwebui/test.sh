#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/openwebui
SNAP=/snap/openwebui/current
mkdir -p $SNAP
ln -s ${BUILD_DIR} $SNAP/openwebui

$BUILD_DIR/usr/local/bin/python3 --version
#export PYTHONPATH="$BUILD_DIR/usr/local/lib/python3.11/site-packages:$BUILD_DIR/usr/local/lib/python3.11/lib-dynload"

$BUILD_DIR/usr/local/bin/python3 -c "import ssl"
$BUILD_DIR/usr/local/bin/python3 -m uvicorn --version

$BUILD_DIR/usr/bin/ffmpeg --help
$BUILD_DIR/bin/ffplay --help
$BUILD_DIR/bin/ffprobe --help
