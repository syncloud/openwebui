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
apt-get update -qq && apt-get install -y -qq sshpass openssh-client curl >/dev/null

DEVICE_SSH="sshpass -p Password1 ssh -p 22 -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@${APP}.${DISTRO}.com"
$DEVICE_SSH "snap install users 2>&1 || snap refresh users 2>&1 || true; snap list users || true"

trap '
  sshpass -p Password1 ssh -p 22 -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@${APP}.${DISTRO}.com "journalctl --since \"15 min ago\" --no-pager" > "$ART/journalctl.log" 2>&1 || true
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

for host in ${APP} users auth; do
  URL=https://${host}.${DISTRO}.com/
  echo "waiting for ${URL} to return 200 (max 180s)"
  for i in $(seq 1 60); do
    code=$(curl -sk -o /dev/null -w '%{http_code}' "${URL}")
    [ "$code" = "200" ] && break
    sleep 3
  done
  echo "${URL} -> ${code}"
done

cd web
npm ci
PLAYWRIGHT_DOMAIN=${DISTRO}.com \
PLAYWRIGHT_APP=${APP} \
PLAYWRIGHT_VERSION=${VERSION} \
NO_EMAIL_USER=noemail \
NO_EMAIL_PASSWORD=Password1 \
  npx playwright test --project=${PROJECT}
