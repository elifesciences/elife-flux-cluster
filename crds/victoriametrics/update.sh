#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a template-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 0.21.3\`"
    exit 1
fi

cd $(dirname $0)

curl -O https://raw.githubusercontent.com/VictoriaMetrics/helm-charts/victoria-metrics-k8s-stack-$1/charts/victoria-metrics-k8s-stack/charts/crds/crds/crd.yaml
