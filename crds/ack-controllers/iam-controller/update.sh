#!/bin/bash

# As script to
if [ -z "$1" ]; then
    echo 'ERROR: specify a iam-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 1.0.1\`"
    exit 1
fi

cd $(dirname $0)


# Adopted from https://github.com/aws-controllers-k8s/iam-controller/tree/main/config/crd/bases

curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/iam-controller/refs/tags/v$1/config/crd/bases/iam.services.k8s.aws_groups.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/iam-controller/refs/tags/v$1/config/crd/bases/iam.services.k8s.aws_instanceprofiles.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/iam-controller/refs/tags/v$1/config/crd/bases/iam.services.k8s.aws_openidconnectproviders.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/iam-controller/refs/tags/v$1/config/crd/bases/iam.services.k8s.aws_policies.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/iam-controller/refs/tags/v$1/config/crd/bases/iam.services.k8s.aws_roles.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/iam-controller/refs/tags/v$1/config/crd/bases/iam.services.k8s.aws_servicelinkedroles.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/iam-controller/refs/tags/v$1/config/crd/bases/iam.services.k8s.aws_users.yaml
