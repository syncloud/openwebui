#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/openwebui
mkdir -p ${BUILD_DIR}
cp -r /bin ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
cp -r /app ${BUILD_DIR}

apt update
apt install -y patchelf

SNAP=/snap/openwebui/current
mkdir -p $SNAP
ln -s ${BUILD_DIR} $SNAP/openwebui

LD=$(echo $SNAP/isr/lib/*/ld-*.so*)
LIBS=$(echo echo $SNAP/usr/lib/*linux*)
echo $LD
PYTHON=${BUILD_DIR}/usr/local/bin/python3
patchelf --set-interpreter $LD $PYTHON
patchelf --set-rpath $LIBS $PYTHON
$PYTHON --version
