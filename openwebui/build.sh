#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/openwebui
mkdir -p ${BUILD_DIR}

cp -r /usr ${BUILD_DIR}
cp -r /app ${BUILD_DIR}
cp -r $DIR/bin ${BUILD_DIR}

rm -rf ${BUILD_DIR}/usr/lib/gcc
rm -rf ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/playwright

SNAP=/snap/openwebui/current
SNAP_DATA=/var$SNAP
mkdir -p $SNAP
mkdir -p $SNAP_DATA
ln -s $BUILD_DIR $SNAP/openwebui
rm -rf $BUILD_DIR/app/backend/open_webui/static
ln -s $SNAP_DATA/static $BUILD_DIR/app/backend/open_webui/static

PYTHON=${BUILD_DIR}/bin/python
$PYTHON --version
$PYTHON -c "import ssl; print(ssl.OPENSSL_VERSION)"
$PYTHON -m uvicorn --version
