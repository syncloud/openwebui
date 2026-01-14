#!/bin/bash -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )
exec $DIR/openwebui/sbin/python ${DIR}/openwebui/usr/local/bin/gunicorn -c $DIR/openwebui/usr/src/openwebui/gunicorn.conf.py openwebui.asgi:application

