#!/bin/bash

# As script to
if [ -z "$1" ]; then
    echo 'ERROR: specify a s3-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 1.0.1\`"
    exit 1
fi

cd $(dirname $0)


curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/s3-controller/refs/tags/v$1/config/crd/bases/s3.services.k8s.aws_buckets.yaml
