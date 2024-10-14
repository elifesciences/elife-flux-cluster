#!/bin/bash

# As script to
if [ -z "$1" ]; then
    echo 'ERROR: specify a sqs-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 1.0.1\`"
    exit 1
fi

cd $(dirname $0)

curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/sqs-controller/refs/tags/v$1/config/crd/bases/sqs.services.k8s.aws_queues.yaml
