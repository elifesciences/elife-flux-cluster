#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a keda-http-add-on release version to get the CRDs'
    echo "e.g. \`$0 0.7.0\`"
    exit 1
fi

cd $(dirname $0)

curl -sL https://raw.githubusercontent.com/kedacore/http-add-on/refs/tags/v$1/config/crd/bases/http.keda.sh_httpscaledobjects.yaml > keda-http-add-on.crd.yaml
