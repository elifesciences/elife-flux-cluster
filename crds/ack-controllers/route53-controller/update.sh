#!/bin/bash

# As script to
if [ -z "$1" ]; then
    echo 'ERROR: specify a route53-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 1.0.1\`"
    exit 1
fi

cd $(dirname $0)

# Adopted from https://github.com/aws-controllers-k8s/route53-controller/tree/main/config/crd/bases
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/route53-controller/refs/tags/v$1/config/crd/bases/route53.services.k8s.aws_healthchecks.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/route53-controller/refs/tags/v$1/config/crd/bases/route53.services.k8s.aws_hostedzones.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/route53-controller/refs/tags/v$1/config/crd/bases/route53.services.k8s.aws_recordsets.yaml
