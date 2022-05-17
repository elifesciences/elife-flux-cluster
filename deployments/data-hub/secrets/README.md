# Data-hub secrets

This file documents each secret in data-hub, and how to regenerate if necessary.

Each secret will need at least:
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/) (to generate the secret)
- [`kubeseal`](https://github.com/bitnami-labs/sealed-secrets/releases) (to encrypt it).

The example commands will be run from the root of a checkout of this repository. In general, they will follow the same procedure:
1. create a secret file
2. create a sealed secret
3. remove the secret file

You will need to commit the sealed secret file, and create a PR and merge to the repo to update the credentials in the cluster.
Data-hub will need restarting to start using the new credentials.

# `credentials.yaml`

## Description
This secret contains the AWS credentials file used by data-hub. This is a format used by AWS cli and SDK tools, in ini format like the example below:

```
[default]
aws_access_key_id = AKIAxxxxxxxxxxx
aws_secret_access_key = xxxxxxxxxxx
region = us-east-1
```

## Regenerate
```
kubectl create secret generic --dry-run=client credentials --namespace data-hub --from-file=path/to/credentials -o yaml > deployments/data-hub/secrets/credentials-unsealed.yaml
kubeseal --cert ./kubeseal-public.pem --format=yaml -f deployments/data-hub/secrets/credentials-unsealed.yaml > deployments/data-hub/secrets/credentials.yaml
rm deployments/data-hub/secrets/credentials-unsealed.yaml
```
