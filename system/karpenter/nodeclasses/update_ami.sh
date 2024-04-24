#!/bin/bash


if [ -z "$1" ]; then
    echo 'ERROR: specify a eks release version to update the AMIs'
    echo "e.g. \`$0 1.28\`"
    exit 1
fi

# This script updates these params to the latest recommended AMI for each supported architecture and Kubernetes version.
ARM_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/$1/amazon-linux-2-arm64/recommended/image_id --query Parameter.Value --output text)"
AMD_AMI_ID="$(aws ssm get-parameter --name /aws/service/eks/optimized-ami/$1/amazon-linux-2/recommended/image_id --query Parameter.Value --output text)"

# use yq to update the nodeclass yaml file with the new AMIs
yq -i e '.spec.amiSelectorTerms = [{"id": "'$ARM_AMI_ID'"}, {"id": "'$AMD_AMI_ID'"}]' $(dirname $0)/general.yaml
yq -i e '(.spec.amiSelectorTerms[0].id) line_comment="ARM64 AMI ID"' $(dirname $0)/general.yaml
yq -i e '(.spec.amiSelectorTerms[1].id) line_comment="AMD64 AMI ID"' $(dirname $0)/general.yaml
