#!/bin/bash

# As script to
if [ -z "$1" ]; then
    echo 'ERROR: specify a template-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 1.0.1\`"
    exit 1
fi

cd $(dirname $0)


curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/elasticache-controller/refs/tags/v$1/config/crd/bases/elasticache.services.k8s.aws_cacheclusters.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/elasticache-controller/refs/tags/v$1/config/crd/bases/elasticache.services.k8s.aws_cacheparametergroups.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/elasticache-controller/refs/tags/v$1/config/crd/bases/elasticache.services.k8s.aws_cachesubnetgroups.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/elasticache-controller/refs/tags/v$1/config/crd/bases/elasticache.services.k8s.aws_replicationgroups.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/elasticache-controller/refs/tags/v$1/config/crd/bases/elasticache.services.k8s.aws_snapshots.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/elasticache-controller/refs/tags/v$1/config/crd/bases/elasticache.services.k8s.aws_users.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/elasticache-controller/refs/tags/v$1/config/crd/bases/elasticache.services.k8s.aws_usergroups.yaml
