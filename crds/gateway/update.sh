#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a gateway release version to get the CRDs'
    echo "e.g. \`$0 1.0.0\`"
    exit 1
fi

cd $(dirname $0)

curl -sL kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v$1/standard-install.yaml > gateway-api.crd.yaml
