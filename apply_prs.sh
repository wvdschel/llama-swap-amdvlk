#!/bin/bash
set -exo pipefail

if [[ ${#} -lt 1 ]]; then
  echo no list of PRS provided 
  exit 1
fi

for i in ${@}; do
  export PATCH=/build/${i}.patch
  curl -L https://github.com/ggml-org/llama.cpp/pull/${i}.patch > ${PATCH}
  (cd /build/llama.cpp; git apply ${PATCH})
done
