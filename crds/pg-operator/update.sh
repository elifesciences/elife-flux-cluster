#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a psmdb-operator helm chart git reference to get the CRDs'
    echo "e.g. \`$0 1.12.0\`"
    exit 1
fi

cd $(dirname $0)

curl -sO https://raw.githubusercontent.com/percona/percona-helm-charts/pg-operator-$1/charts/pg-operator/crds/crd.yaml
