#!/bin/bash

# As script to
if [ -z "$1" ]; then
    echo 'ERROR: specify a cloudfront-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 1.0.1\`"
    exit 1
fi

cd $(dirname $0)

# https://github.com/aws-controllers-k8s/cloudfront-controller/tree/main/config/crd/bases
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/cloudfront-controller/refs/tags/v$1/config/crd/bases/cloudfront.services.k8s.aws_cachepolicies.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/cloudfront-controller/refs/tags/v$1/config/crd/bases/cloudfront.services.k8s.aws_distributions.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/cloudfront-controller/refs/tags/v$1/config/crd/bases/cloudfront.services.k8s.aws_functions.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/cloudfront-controller/refs/tags/v$1/config/crd/bases/cloudfront.services.k8s.aws_originaccesscontrols.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/cloudfront-controller/refs/tags/v$1/config/crd/bases/cloudfront.services.k8s.aws_originrequestpolicies.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/cloudfront-controller/refs/tags/v$1/config/crd/bases/cloudfront.services.k8s.aws_responseheaderspolicies.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/cloudfront-controller/refs/tags/v$1/config/crd/bases/cloudfront.services.k8s.aws_vpcorigins.yaml
