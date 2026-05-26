#!/bin/bash -ex

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

OUT=${DIR}/../build/snap
mkdir -p ${OUT}/meta/hooks ${OUT}/bin

for cmd in install configure pre-refresh post-refresh; do
  CGO_ENABLED=0 go build -o ${OUT}/meta/hooks/${cmd} ./cmd/${cmd}
done
CGO_ENABLED=0 go build -o ${OUT}/bin/cli ./cmd/cli
