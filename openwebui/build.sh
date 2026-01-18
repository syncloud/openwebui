#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/openwebui
mkdir -p ${BUILD_DIR}

#rm -rf /usr/local/lib/python3.11/site-packages/*.pth
cp -r /usr ${BUILD_DIR}
cp -r /app ${BUILD_DIR}

apt update
apt install -y patchelf

SNAP=/snap/openwebui/current
SNAP_DATA=/var$SNAP
mkdir -p $SNAP
mkdir -p $SNAP_DATA
ln -s $BUILD_DIR $SNAP/openwebui
rm -rf $BUILD_DIR/app/backend/static
ln -s $SNAP_DATA/static $BUILD_DIR/app/backend/static

PYTHON=${BUILD_DIR}/usr/local/bin/python3
ldd $PYTHON
LD=$(echo $SNAP/openwebui/usr/lib/*/ld-*.so*)
LIBS=$LIBS:$SNAP/openwebui/usr/local/lib
LIBS=$LIBS:$(echo $SNAP/openwebui/usr/lib/*linux*/)

echo $LD
echo $LIBS
patchelf --set-interpreter $LD $PYTHON
patchelf --set-rpath $LIBS $PYTHON
$PYTHON --version
$PYTHON -c "import ssl; print(ssl.OPENSSL_VERSION)"
$PYTHON -m uvicorn --version
