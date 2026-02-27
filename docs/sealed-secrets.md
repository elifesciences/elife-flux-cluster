
SealedSecrets
=============

NOTE: the preferred way to get secrets into the cluster is via ExternalSecretsOperator

The cluster has a [sealed-secrets](https://github.com/bitnami-labs/sealed-secrets) controller.

- `SealedSecrets` are encrypted and safe to store in git
- use `kubeseal` to generate `SealedSecret` yaml files
- controller decrypts them and creates `Secret` objects

Benefits of this approach are:

- improved disaster recovery as secrets are recovered from git repo
- devs can update and add secrets without needing access to the cluster

This approach doesn't let us share secrets with devs.
Such a scenario is probably better served with Vault.

## Creating/Updating SealedSecrets

- install `kubeseal` client from [Github Releases Page](https://github.com/bitnami-labs/sealed-secrets/releases)
- use `kubeseal-public.pem` to encrypt a secret (see [docs](https://github.com/bitnami-labs/sealed-secrets#usage))
- see [k8s docs](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/#create-a-secret) for ways to create a `Secret` through cli
- see [k8 docs](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-config-file/) for ways to create a `Secret` through config `yaml` files

```
kubeseal \
    --cert ./kubeseal-public.pem \
    --format=yaml <your-secret.yaml > your-secret-as-a-sealedsecret.yaml
```

NOTE: You can't change the `name` or `namespace` field of a `SealedSecret` yaml file after it has been created as these values are used to to encrypt the content. If you change these decryption will fail.

## Backup and Recovery

The master/private key is backed up in `it-admin`.

The recovery process is to replace the auto-generated private key with the key from backup and restart the controller:

```
kubectl replace secret -n infra sealed-secrets-key -f sealed-secrets-key.yaml
kubectl delete pod -n infra -l app=sealed-secrets
```
