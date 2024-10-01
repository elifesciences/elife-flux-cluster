#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a sealed-secrets helm chart git reference to get the CRDs'
    echo "e.g. \`$0 v0.24.5\`"
    exit 1
fi

cd $(dirname $0)

curl -sO https://raw.githubusercontent.com/bitnami-labs/sealed-secrets/helm-v$1/helm/sealed-secrets/crds/bitnami.com_sealedsecrets.yaml
