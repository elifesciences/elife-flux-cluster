#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a keda release version to get the CRDs'
    echo "e.g. \`$0 2.41.1\`"
    exit 1
fi

cd $(dirname $0)

curl -sL https://raw.githubusercontent.com/Kong/charts/refs/tags/gateway-operator-$1/charts/gateway-operator/charts/kubernetes-configuration-crds/crds/kubernetes-configuration-crds.yaml > kong-config.crd.yaml
