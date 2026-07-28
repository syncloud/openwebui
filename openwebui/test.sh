#!/bin/sh -ex

DIR=$( cd "$( dirname "$0" )" && pwd )
cd ${DIR}

BUILD_DIR=${DIR}/../build/snap/openwebui
SNAP=/snap/openwebui/current
mkdir -p $SNAP
ln -s ${BUILD_DIR} $SNAP/openwebui

PYTHON=$BUILD_DIR/bin/python
$PYTHON --version
$PYTHON -c "import ssl"
$PYTHON -c "import en_core_web_sm; en_core_web_sm.load()"
$PYTHON -m uvicorn --version

$BUILD_DIR/bin/ffmpeg --help
$BUILD_DIR/bin/ffplay --help
$BUILD_DIR/bin/ffprobe --help
$BUILD_DIR/bin/pandoc --version
