#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a cert-manager release version to get the CRDs'
    echo "e.g. \`$0 v1.15.3\`"
    exit 1
fi

cd $(dirname $0)

curl -sL https://github.com/cert-manager/cert-manager/releases/download/$1/cert-manager.crds.yaml > cert-manager.crd.yaml
