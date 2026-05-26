#!/bin/sh -ex

PROJECT=$1
APP=$2
DISTRO=$3
VERSION=$4

PLATFORM_IP=$(getent hosts ${APP}.${DISTRO}.com | awk '{print $1}')
for host in auth users; do
  echo "${PLATFORM_IP} ${host}.${DISTRO}.com" | tee -a /etc/hosts
done

ART=/drone/src/artifact/e2e/${PROJECT}
mkdir -p "$ART"
trap '
  find /drone/src/web/test-results -maxdepth 2 -name "*.png" -exec cp {} "$ART/" \; 2>/dev/null
  for d in /drone/src/web/test-results/*/; do
    base=$(basename "$d")
    if ls "$d"error-context.md "$d"trace.zip >/dev/null 2>&1; then
      mkdir -p "$ART/errors/$base"
      cp "$d"error-context.md "$d"trace.zip "$ART/errors/$base/" 2>/dev/null
    fi
  done
  chmod -R a+r "$ART" 2>/dev/null
  exit
' EXIT INT TERM

APP_URL=https://${APP}.${DISTRO}.com/
echo "waiting for ${APP_URL} to return 200"
until curl -sk -o /dev/null -w '%{http_code}\n' "${APP_URL}" | grep -q '^200$'; do
  sleep 3
done
echo "${APP_URL} is ready"

cd web
npm ci
PLAYWRIGHT_DOMAIN=${DISTRO}.com \
PLAYWRIGHT_APP=${APP} \
PLAYWRIGHT_VERSION=${VERSION} \
NO_EMAIL_USER=noemail \
NO_EMAIL_PASSWORD=Password1 \
  npx playwright test --project=${PROJECT}
