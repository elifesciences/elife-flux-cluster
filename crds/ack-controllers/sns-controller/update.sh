#!/bin/bash

# As script to
if [ -z "$1" ]; then
    echo 'ERROR: specify a sns-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 1.0.1\`"
    exit 1
fi

cd $(dirname $0)


curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/sns-controller/refs/tags/v$1/config/crd/bases/sns.services.k8s.aws_platformapplications.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/sns-controller/refs/tags/v$1/config/crd/bases/sns.services.k8s.aws_platformendpoints.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/sns-controller/refs/tags/v$1/config/crd/bases/sns.services.k8s.aws_subscriptions.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/sns-controller/refs/tags/v$1/config/crd/bases/sns.services.k8s.aws_topics.yaml
