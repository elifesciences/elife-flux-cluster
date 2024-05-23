
#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a karpenter git reference to get the CRDs'
    echo "e.g. \`$0 v0.36.1\`"
    exit 1
fi

cd $(dirname $0)

curl -O https://raw.githubusercontent.com/aws/karpenter-provider-aws/$1/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml
curl -O https://raw.githubusercontent.com/aws/karpenter-provider-aws/$1/pkg/apis/crds/karpenter.sh_nodeclaims.yaml
curl -O https://raw.githubusercontent.com/aws/karpenter-provider-aws/$1/pkg/apis/crds/karpenter.sh_nodepools.yaml
curl -O https://raw.githubusercontent.com/kubernetes-sigs/karpenter/main/kwok/apis/crds/kwok.karpenter.sh_kwoknodeclasses.yaml
