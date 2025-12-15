#!/bin/bash

# As script to
if [ -z "$1" ]; then
    echo 'ERROR: specify a s3-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 1.0.1\`"
    exit 1
fi

cd $(dirname $0)

# Note: Use S3 as one of the earliest and most up-to-date controllers to pull these common CRDs from
# https://github.com/aws-controllers-k8s/s3-controller/tree/main/config/crd/common/bases

curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/s3-controller/refs/tags/v$1/config/crd/common/bases/services.k8s.aws_fieldexports.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/s3-controller/refs/tags/v$1/config/crd/common/bases/services.k8s.aws_iamroleselectors.yaml
