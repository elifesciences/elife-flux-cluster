#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a template-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 0.2.2\`"
    exit 1
fi

cd $(dirname $0)

curl -sO https://raw.githubusercontent.com/kluctl/template-controller/refs/tags/v$1/deploy/crds/bundle.yaml
