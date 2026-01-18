#!/bin/bash -e

DIR=$( cd "$( dirname "$0" )" && cd .. && pwd )

cd $DIR/ollama
source $SNAP_DATA/config/ollama.env
exec $DIR/ollama/bin/ollama serve
bui/usr/local/bin/python3 \
    -m uvicorn open_webui.main:app \
    --uds $SNAP_COMMON/web.socket \
    --forwarded-allow-ips '*' \
    --workers 1
