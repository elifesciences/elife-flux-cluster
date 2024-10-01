#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a keda-http-add-on release version to get the CRDs'
    echo "e.g. \`$0 0.7.0\`"
    exit 1
fi

cd $(dirname $0)

curl -sL https://github.com/kedacore/http-add-on/releases/download/v$1/keda-http-add-on-$1-crds.yaml > keda-http-add-on.crd.yaml
