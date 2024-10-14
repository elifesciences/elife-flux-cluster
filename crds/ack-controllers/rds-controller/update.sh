#!/bin/bash

# As script to
if [ -z "$1" ]; then
    echo 'ERROR: specify a rds-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 1.0.1\`"
    exit 1
fi

cd $(dirname $0)


curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/rds-controller/refs/tags/v$1/config/crd/bases/rds.services.k8s.aws_dbclusters.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/rds-controller/refs/tags/v$1/config/crd/bases/rds.services.k8s.aws_dbclusterparametergroups.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/rds-controller/refs/tags/v$1/config/crd/bases/rds.services.k8s.aws_dbclustersnapshots.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/rds-controller/refs/tags/v$1/config/crd/bases/rds.services.k8s.aws_dbinstances.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/rds-controller/refs/tags/v$1/config/crd/bases/rds.services.k8s.aws_dbparametergroups.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/rds-controller/refs/tags/v$1/config/crd/bases/rds.services.k8s.aws_dbproxies.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/rds-controller/refs/tags/v$1/config/crd/bases/rds.services.k8s.aws_dbsnapshots.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/rds-controller/refs/tags/v$1/config/crd/bases/rds.services.k8s.aws_dbsubnetgroups.yaml
curl -sO https://raw.githubusercontent.com/aws-controllers-k8s/rds-controller/refs/tags/v$1/config/crd/bases/rds.services.k8s.aws_globalclusters.yaml
