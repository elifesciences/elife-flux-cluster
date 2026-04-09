#!/bin/bash

# A script to update the Pipeline CRD from a specific commit SHA
# Use the SHA from the deployed image tag, e.g. from update_all.sh

if [ -z "$1" ]; then
    echo 'ERROR: specify a commit SHA to get the CRDs'
    echo "e.g. \`$0 abc1234\`"
    exit 1
fi

cd $(dirname $0)

curl -sL https://raw.githubusercontent.com/elifesciences/app-conveyor/$1/crds/pipeline.yaml | yq -P > pipeline.crd.yaml
