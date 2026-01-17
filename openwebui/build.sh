#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/openwebui
mkdir -p ${BUILD_DIR}
cp -r /bin ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
cp -r /app ${BUILD_DIR}
cp -r $DIR/bin/* ${BUILD_DIR}/bin/

apt update
apt install -y patchelf strace

SNAP=/snap/openwebui/current
mkdir -p $SNAP
ln -s ${BUILD_DIR} $SNAP/openwebui

LD=$(echo $SNAP/openwebui/usr/lib/*/ld-*.so*)
LIBS=$(echo $SNAP/openwebui/usr/lib/*linux*/)
echo $LD
echo $LIBS

python --version
strace python -c "import ssl" 2>&1 | grep -v "No such file"
python -m uvicorn --version

strings /usr/local/lib/python3.11/lib-dynload/_ssl.cpython-311-*-linux-gnu.so  | grep PyMod

$BUILD_DIR/bin/python --version
strace $BUILD_DIR/bin/python -c "import ssl" 2>&1 | grep openat | grep "\.so"
$BUILD_DIR/bin/python -m uvicorn --version

PYTHON=${BUILD_DIR}/usr/local/bin/python3
ldd $PYTHON

patchelf --set-interpreter $LD $PYTHON
patchelf --set-rpath $LIBS $PYTHON
$PYTHON --version
