#!/bin/sh -ex

PROJECT=$1
APP=$2
DISTRO=$3
VERSION=$4

apt-get update -qq && apt-get install -y -qq sshpass openssh-client curl >/dev/null

export PLAYWRIGHT_APP=${APP}
export PLAYWRIGHT_DOMAIN=${DISTRO}.com
export PLAYWRIGHT_VERSION=${VERSION}
export PLAYWRIGHT_ARTIFACT_DIR=/drone/src/artifact
export NO_EMAIL_USER=noemail
export NO_EMAIL_PASSWORD=Password1

cd web
npm ci
npx playwright test --project=${PROJECT}
