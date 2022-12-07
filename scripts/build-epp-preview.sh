#!/bin/bash
set -e
re='^[0-9]+$'
if ! [[ $1  =~ $re ]]; then
    echo "first param must be a PR number"
    exit 1
fi
pr_id=$1

PREVIEWS_DIR='deployments/epp/previews'
ENV_NAME_PREFIX='epp-preview'
HOSTNAME_SUFFIX='epp'
ORG='elifesciences'
KUSTOMIZATION_TEMPLATE='kustomizations/apps/epp/preview_template.yaml'

# export image_tag="preview-${pr_commit:0:8}"
export deployment_name="$ENV_NAME_PREFIX-${pr_id}"
export deployment_hostname="pr-${pr_id}--${HOSTNAME_SUFFIX}.elifesciences.org"

ENV_DEST_DIR="${PREVIEWS_DIR}/$pr_id"
echo "Creating env for PR $pr_id at ${ENV_DEST_DIR}"
mkdir -p "${ENV_DEST_DIR}" | true

echo "create namespace at ${ENV_DEST_DIR}/namespace.yaml"
yq ".metadata.name = \"${deployment_name}\"" kustomizations/apps/epp/preview/namespace_template.yaml > ${ENV_DEST_DIR}/namespace.yaml

echo "create database at ${ENV_DEST_DIR}/mongodb-release.yaml "
yq ".metadata.namespace = \"${deployment_name}\" | .metadata.labels.app_env = \"${deployment_name}\"" kustomizations/apps/epp/preview/mongodb-release_template.yaml > ${ENV_DEST_DIR}/mongodb-release.yaml

echo "create kustomization at ${ENV_DEST_DIR}/epp-kustomization.yaml "
cp kustomizations/apps/epp/preview/epp-kustomization_template.yaml ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".metadata.namespace = \"${deployment_name}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".spec.targetNamespace = \"${deployment_name}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".spec.postBuild.substitute.app_env = \"${deployment_name}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".spec.postBuild.substitute.app_hostname = \"${deployment_hostname}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".spec.postBuild.substitute.asset_prefix = \"https://${deployment_hostname}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".spec.postBuild.substitute.iiif_server = \"https://${deployment_hostname}/iiif\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
