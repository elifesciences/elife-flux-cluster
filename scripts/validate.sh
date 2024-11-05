#!/usr/bin/env bash

# This script downloads the Flux OpenAPI schemas, then it validates the
# Flux custom resources and the kustomize overlays using kubeconform.
# This script is meant to be run locally and in CI before the changes
# are merged on the main branch that's synced by Flux.

# Copyright 2020 The Flux authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script is meant to be run locally and in CI to validate the Kubernetes
# manifests (including Flux custom resources) before changes are merged into
# the branch synced by Flux in-cluster.

# Prerequisites
# - yq v4.6
# - kustomize v4.1
# - kubeconform v0.4.12


## Set up Additional Environment variables that need values for clusters
export temporal_web_hostname="test"
export temporal_store_host="test"
export temporal_store_user="test"
export temporal_visibility_store_host="test"
export temporal_visibility_store_user="test"
export temporal_store_password_secret_name="test"
export temporal_store_password_secret_key="test"
export temporal_visibility_store_password_secret_name="test"
export temporal_visibility_store_password_secret_key="test"
export keda_autoscaler_namespace_fix="test"
export app_hostname="test"
export epp_server_role_arn="test"
export iiif_server="test"
export image_server_role_arn="test"
export image_server_s3_bucket="test"
export import_role_arn="test"
export journal_api_hostname="test"
export mongodb_hostname="test"
export app_env="test"
export epp_server="test"
export s3_bucket="test"
export temporal_namespace="test"
export temporal_server="test"
export ts="test"
export env="test"
export hostname="test"

# Settings for various tool calls
#
kubeconform_config="-strict -ignore-missing-schemas -schema-location default -schema-location /tmp/flux-crd-schemas -verbose -skip Canary,HelmRelease"
# mirror kustomize-controller build options
kustomize_flags="--load-restrictor=LoadRestrictionsNone"
kustomize_config="kustomization.yaml"


echo "# INFO - Validating yaml files are valid YAML"
# find . -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file;
#   do
#     echo "## INFO - Validating yaml $file"
#     yq e 'true' "$file" > /dev/null
# done
# echo ""

echo "# INFO - Validating clusters is conforming to flux schema"
echo "## INFO - Downloading Flux OpenAPI schemas"
mkdir -p /tmp/flux-crd-schemas/master-standalone-strict
curl -sL https://github.com/fluxcd/flux2/releases/latest/download/crd-schemas.tar.gz | tar zxf - -C /tmp/flux-crd-schemas/master-standalone-strict
find ./clusters -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "## INFO - Validating cluster file ${file}"
    conform_output=$(kubeconform $kubeconform_config ${file})
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
      echo "## ERROR ${file} cause a kubeconform error"
      echo $conform_output
      exit 1
    fi
done


echo "# INFO - Validating kustomize overlays (excluding ./clusters path)"
find . -type f -name $kustomize_config -not -path "./clusters/*" -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "## INFO - Validating kustomization ${file/%$kustomize_config}"
    tmp_dir=$(mktemp -d)

    kustomize build "${file/%$kustomize_config}" $kustomize_flags > $tmp_dir/kustomize_output 2> $tmp_dir/kustomize_error
    if [[ $? != 0 ]]; then
      echo "## ERROR ${file/%$kustomize_config} failed kustomize build"
      cat $tmp_dir/kustomize_error
      rm -Rf $tmp_dir
      # echo $tmp_dir
      exit 1
    fi

    cat $tmp_dir/kustomize_output | kubeconform $kubeconform_config > $tmp_dir/kubeconform_output 2> $tmp_dir/kubeconform_error
    if [[ ${PIPESTATUS[1]} != 0 ]]; then
      echo "## INFO ${file/%$kustomize_config} failed kubeconform, trying with envsubst"
      cat $tmp_dir/kustomize_output | flux envsubst --strict > $tmp_dir/envsubst_output 2> $tmp_dir/envsubst_error
      if [[ ${PIPESTATUS[1]} != 0 ]]; then
        echo "## ERROR ${file/%$kustomize_config} failed envsubst"
        cat $tmp_dir/envsubst_error
        rm -Rf $tmp_dir
        # echo $tmp_dir
        exit 1
      fi

      cat $tmp_dir/envsubst_output | kubeconform $kubeconform_config > $tmp_dir/kubeconform_output 2> $tmp_dir/kubeconform_error
      if [[ ${PIPESTATUS[1]} != 0 ]]; then
        echo "## ERROR ${file/%$kustomize_config} failed kubeconform"
        cat $tmp_dir/kubeconform_error
        cat $tmp_dir/kubeconform_output
        rm -Rf $tmp_dir
        # echo $tmp_dir
        exit 1
      fi
    fi

    rm -Rf $tmp_dir
done
