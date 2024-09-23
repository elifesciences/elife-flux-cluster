#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a keda release version to get the CRDs'
    echo "e.g. \`$0 2.41.1\`"
    exit 1
fi

cd $(dirname $0)

curl -L https://raw.githubusercontent.com/Kong/charts/refs/tags/kong-$1/charts/gateway-operator/crds/custom-resource-definitions.yaml > kong.crd.yaml
