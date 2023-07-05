#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a psmdb-operator helm chart git reference to get the CRDs'
    echo "e.g. \`$0 1.12.0\`"
    exit 1
fi

cd $(dirname $0)

curl -O https://raw.githubusercontent.com/percona/percona-helm-charts/psmdb-operator-$1/charts/psmdb-operator/crds/crd.yaml
