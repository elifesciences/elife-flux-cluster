#!/bin/bash
# Fetches the suggested manifest from the latest github release
set -euo pipefail

LATEST_TAG=$(curl \
  -s -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest \
  | jq -r '.tag_name')

cd "${BASH_SOURCE%/*}" || exit
curl \
  -s -L -H "Accept: application/octet-stream" \
  https://github.com/bitnami-labs/sealed-secrets/releases/download/${LATEST_TAG}/controller.yaml \
  > kube-system/sealed-secrets.yaml
