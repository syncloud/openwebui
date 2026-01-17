#!/bin/bash -e

DIR=$( cd "$( dirname "$0" )" && cd .. && pwd )

export WEBUI_SECRET_KEY=$(cat $SNAP_DATA/webui_secret_key)
cd $DIR/openwebui/app/backend
exec $DIR/openwebui/usr/local/bin//python3 \
    -m uvicorn open_webui.main:app \
    --uds $SNAP_COMMON\web.socket
    --forwarded-allow-ips '*' \
    --workers 1
   
