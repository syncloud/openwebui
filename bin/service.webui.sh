#!/bin/bash -e

DIR=$( cd "$( dirname "$0" )" && cd .. && pwd )

export OPENSSL_VERIFY=0
export HTTPX_VERIFY=false
#export SSL_CERT_FILE=/var/snap/platform/current/syncloud.ca.crt
#export REQUESTS_CA_BUNDLE=/var/snap/platform/current/syncloud.ca.crt
export PATH=$DIR/openwebui/bin:$PATH
cd $DIR/openwebui/app/backend
source $SNAP_DATA/config/openwebui.env
exec $DIR/openwebui/usr/local/bin/python3 \
    -m uvicorn open_webui.main:app \
    --uds $SNAP_COMMON/web.socket \
    --forwarded-allow-ips '*' \
    --workers 1
