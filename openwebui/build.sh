#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}
BUILD_DIR=${DIR}/../build/snap/openwebui
mkdir -p ${BUILD_DIR}
apt update
apt install -y wget tesseract-ocr-all

cp -r /bin ${BUILD_DIR}
cp -r /usr ${BUILD_DIR}
cp -r /lib ${BUILD_DIR}
sed -i 's#bind.*=.*#bind="unix:/var/snap/openwebui/common/web.socket"#g' ${BUILD_DIR}/usr/src/openwebui/gunicorn.conf.py
grep bind ${BUILD_DIR}/usr/src/openwebui/gunicorn.conf.py

cp --remove-destination -R ${BUILD_DIR}/usr/src/openwebui/src/documents/static/* ${BUILD_DIR}/usr/src/openwebui/static
ls -la ${BUILD_DIR}/usr/src/openwebui/static

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/django/contrib/admin/static/* ${BUILD_DIR}/usr/src/openwebui/static
ls -la ${BUILD_DIR}/usr/src/openwebui/static/admin/css

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/django_extensions/static/* ${BUILD_DIR}/usr/src/openwebui/static
ls -la ${BUILD_DIR}/usr/src/openwebui/static/django_extensions/css

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/guardian/static/* ${BUILD_DIR}/usr/src/openwebui/static
ls -la ${BUILD_DIR}/usr/src/openwebui/static/guardian/img

cp --remove-destination -R ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/rest_framework/static/* ${BUILD_DIR}/usr/src/openwebui/static
ls -la ${BUILD_DIR}/usr/src/openwebui/static/rest_framework/img

cp --remove-destination -R ${BUILD_DIR}/usr/src/openwebui/src/openwebui/static/* ${BUILD_DIR}/usr/src/openwebui/static
ls -la ${BUILD_DIR}/usr/src/openwebui/static/openwebui/img

cp --remove-destination -R ${DIR}/bin ${BUILD_DIR}/sbin

wget https://github.com/cyberb/openwebui-ngx/archive/refs/heads/dev.tar.gz
tar xf dev.tar.gz
cp openwebui-ngx-dev/src/openwebui/adapter.py ${BUILD_DIR}/usr/src/openwebui/src/openwebui
cp openwebui-ngx-dev/src/openwebui/settings.py ${BUILD_DIR}/usr/src/openwebui/src/openwebui

#sed -i 's#return \["openid", "profile", "email"\]#return \["openid", "profile", "email", "groups"\]#g' ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/allauth/socialaccount/providers/openid_connect/provider.py
#grep profile ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/allauth/socialaccount/providers/openid_connect/provider.py

#sed -i 's#username=data.get("preferred_username"),#username=data.get("preferred_username"), groups=data.get("groups"),#g' ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/allauth/socialaccount/providers/openid_connect/provider.py
#grep groups ${BUILD_DIR}/usr/local/lib/python3.11/site-packages/allauth/socialaccount/providers/openid_connect/provider.py

cp -r openwebui-ngx-dev/src/documents/tests/samples/* .
