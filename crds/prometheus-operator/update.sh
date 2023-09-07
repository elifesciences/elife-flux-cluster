#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a prometheus-operator git reference to get the CRDs'
    echo "e.g. \`$0 v0.54.0\`"
    exit 1
fi

cd $(dirname $0)

curl -O https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$1/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
curl -O https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$1/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
curl -O https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$1/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
curl -O https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$1/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
curl -O https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$1/example/prometheus-operator-crd/monitoring.coreos.com_prometheusagents.yaml
curl -O https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$1/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
curl -O https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$1/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
curl -O https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$1/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml
curl -O https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$1/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
curl -O https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$1/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
