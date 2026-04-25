#!/bin/sh -ex

PROJECT=$1
APP=$2
DISTRO=$3
VERSION=$4

apt-get update
apt-get install -y --no-install-recommends sshpass openssh-client

getent hosts ${APP}.${DISTRO}.com | sed "s/${APP}.${DISTRO}.com/auth.${DISTRO}.com/g" | tee -a /etc/hosts

DEVICE_HOST=${APP}.${DISTRO}.com
SSH="sshpass -p ${DEVICE_PASSWORD} ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${DEVICE_HOST}"

NO_EMAIL_USER=noemail
NO_EMAIL_PASSWORD=Password1
${SSH} "snap run platform.cli user remove ${NO_EMAIL_USER}" || true
${SSH} "snap run platform.cli user add ${NO_EMAIL_USER} --password=${NO_EMAIL_PASSWORD}"

ART=/drone/src/artifact/${PROJECT}
mkdir -p "$ART"
trap 'cp -r /drone/src/web/test-results "$ART/" 2>/dev/null; cp -r /drone/src/web/playwright-report "$ART/" 2>/dev/null; chmod -R a+r "$ART" 2>/dev/null; exit' EXIT INT TERM

cd web
npm ci
PLAYWRIGHT_DOMAIN=${DISTRO}.com \
PLAYWRIGHT_APP=${APP} \
PLAYWRIGHT_VERSION=${VERSION} \
NO_EMAIL_USER=${NO_EMAIL_USER} \
NO_EMAIL_PASSWORD=${NO_EMAIL_PASSWORD} \
  npx playwright test --project=${PROJECT}
