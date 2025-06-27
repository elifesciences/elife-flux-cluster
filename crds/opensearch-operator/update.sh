#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a psmdb-operator helm chart git reference to get the CRDs'
    echo "e.g. \`$0 2.8.0\`"
    exit 1
fi

cd $(dirname $0)

curl -sO https://raw.githubusercontent.com/opensearch-project/opensearch-k8s-operator/refs/tags/v$1/charts/opensearch-operator/files/opensearch.opster.io_opensearchactiongroups.yaml
curl -sO https://raw.githubusercontent.com/opensearch-project/opensearch-k8s-operator/refs/tags/v$1/charts/opensearch-operator/files/opensearch.opster.io_opensearchclusters.yaml
curl -sO https://raw.githubusercontent.com/opensearch-project/opensearch-k8s-operator/refs/tags/v$1/charts/opensearch-operator/files/opensearch.opster.io_opensearchcomponenttemplates.yaml
curl -sO https://raw.githubusercontent.com/opensearch-project/opensearch-k8s-operator/refs/tags/v$1/charts/opensearch-operator/files/opensearch.opster.io_opensearchindextemplates.yaml
curl -sO https://raw.githubusercontent.com/opensearch-project/opensearch-k8s-operator/refs/tags/v$1/charts/opensearch-operator/files/opensearch.opster.io_opensearchismpolicies.yaml
curl -sO https://raw.githubusercontent.com/opensearch-project/opensearch-k8s-operator/refs/tags/v$1/charts/opensearch-operator/files/opensearch.opster.io_opensearchroles.yaml
curl -sO https://raw.githubusercontent.com/opensearch-project/opensearch-k8s-operator/refs/tags/v$1/charts/opensearch-operator/files/opensearch.opster.io_opensearchsnapshotpolicies.yaml
curl -sO https://raw.githubusercontent.com/opensearch-project/opensearch-k8s-operator/refs/tags/v$1/charts/opensearch-operator/files/opensearch.opster.io_opensearchtenants.yaml
curl -sO https://raw.githubusercontent.com/opensearch-project/opensearch-k8s-operator/refs/tags/v$1/charts/opensearch-operator/files/opensearch.opster.io_opensearchuserrolebindings.yaml
curl -sO https://raw.githubusercontent.com/opensearch-project/opensearch-k8s-operator/refs/tags/v$1/charts/opensearch-operator/files/opensearch.opster.io_opensearchusers.yaml
