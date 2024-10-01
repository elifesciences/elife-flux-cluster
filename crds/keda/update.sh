#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a keda release version to get the CRDs'
    echo "e.g. \`$0 2.12.1\`"
    exit 1
fi

cd $(dirname $0)

curl -sL https://github.com/kedacore/keda/releases/download/v$1/keda-$1-crds.yaml > keda.crd.yaml
