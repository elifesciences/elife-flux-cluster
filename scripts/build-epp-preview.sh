#!/bin/bash
set -e
re='^[0-9]+$'
if ! [[ $1  =~ $re ]]; then
    echo "first param must be a PR number"
    exit 1
fi
pr_id=$1

if [[ -z $2 ]]; then
    echo "second param must be the server image tag"
    exit 1
fi
servertag=$2

if [[ -z $3 ]]; then
    echo "third param must be the client image tag"
    exit 1
fi
clienttag=$3

if [[ -z $4 ]]; then
    echo "fourth param must be the storybook image tag"
    exit 1
fi
storybooktag=$4

echo "pr_id: $pr_id, server: $servertag, client: $clienttag, storybook: $storybooktag"

PREVIEWS_DIR='deployments/epp/previews'
ENV_NAME_PREFIX='epp--preview'
HOSTNAME_SUFFIX='epp'
STORYBOOK_HOSTNAME_SUFFIX='epp-storybook'
JOURNAL_API_HOSTNAME_SUFFIX='epp-api'
ORG='elifesciences'
KUSTOMIZATION_TEMPLATE='kustomizations/apps/epp/preview_template.yaml'

# export image_tag="preview-${pr_commit:0:8}"
export deployment_name="$ENV_NAME_PREFIX-${pr_id}"
export deployment_hostname="pr-${pr_id}--${HOSTNAME_SUFFIX}.elifesciences.org"
export deployment_storybook_hostname="pr-${pr_id}--${STORYBOOK_HOSTNAME_SUFFIX}.elifesciences.org"
export deployment_journal_api_hostname="pr-${pr_id}--${JOURNAL_API_HOSTNAME_SUFFIX}.elifesciences.org"

ENV_DEST_DIR="${PREVIEWS_DIR}/$pr_id"
echo "Creating env for PR $pr_id at ${ENV_DEST_DIR}"
mkdir -p "${ENV_DEST_DIR}" | true

echo "create namespace at ${ENV_DEST_DIR}/namespace.yaml"
yq ".metadata.name = \"${deployment_name}\"" kustomizations/apps/epp/preview/namespace_template.yaml > ${ENV_DEST_DIR}/namespace.yaml

# echo "create database at ${ENV_DEST_DIR}/mongodb-release.yaml "
# yq ".metadata.namespace = \"${deployment_name}\" | .metadata.labels.app_env = \"${deployment_name}\"" kustomizations/apps/epp/preview/mongodb-release_template.yaml > ${ENV_DEST_DIR}/mongodb-release.yaml

echo "create kustomization at ${ENV_DEST_DIR}/epp-kustomization.yaml "
cp kustomizations/apps/epp/preview/epp-kustomization_template.yaml ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".metadata.namespace = \"${deployment_name}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".spec.targetNamespace = \"${deployment_name}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".spec.postBuild.substitute.app_env = \"${deployment_name}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".spec.postBuild.substitute.app_hostname = \"${deployment_hostname}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".spec.postBuild.substitute.storybook_hostname = \"${deployment_storybook_hostname}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
# yq -i ".spec.postBuild.substitute.journal_api_hostname = \"${deployment_journal_api_hostname}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i ".spec.postBuild.substitute.asset_prefix = \"https://${deployment_hostname}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
# yq -i ".spec.postBuild.substitute.iiif_server = \"https://${deployment_hostname}/iiif\"" ${ENV_DEST_DIR}/epp-kustomization.yaml

# replace image tags
# yq -i "(.spec.images[] | select(.name == \"ghcr.io/elifesciences/enhanced-preprints\") | .newTag) = \"${servertag}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i "(.spec.images[] | select(.name == \"ghcr.io/elifesciences/enhanced-preprints-client\") | .newTag) = \"${clienttag}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
yq -i "(.spec.images[] | select(.name == \"ghcr.io/elifesciences/enhanced-preprints-storybook\") | .newTag) = \"${storybooktag}\"" ${ENV_DEST_DIR}/epp-kustomization.yaml
