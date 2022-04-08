# Upgrading from Fluxv1 to Fluxv1

This document is only relevant during the migration, but is left here for posterity.

## High-level overview

1. Uninstall `flux` v1 (but leave `helm-operator`) and install `flux` v2
2. Migrate `helm-operator` `HelmRelease` to `helm-controller` `HelmSource` and `HelmRelease`
3. Remove `helm-operator`

## Step 1: Uninstall `flux` v1 (but leave `helm-operator`)

All changes to flux resource require `helm-operator` to not be paying attention. We will scale down the `helm-operator` deployment to do this

```shell
helm upgrade -n flux -i --repo https://charts.fluxcd.io helm-operator helm-operator --set helm.versions=v3 # remove the dependency on git.ssh.secretName
kubectl -n flux scale deployment helm-operator --replicas=0 # stop helm-operator
helm uninstall -n flux flux
kubectl delete helmreleases.helm.fluxcd.io -n flux flux # delete flux helmrelease
# merge in the change in the repo that removes flux `helmrelease`, sets up the new kustomization obejects
flux bootstrap github --owner=elifesciences --personal --repository=elife-flux-cluster --path=clusters/flux-prod --components-extra=image-reflector-controller,image-automation-controller --read-write-key --branch master
kubectl -n flux scale deployment helm-operator --replicas=1 # start helm-operator again
```

## Step 2: Migrate `helm-operator` `HelmRelease` to `helm-controller` `HelmSource` and `HelmRelease`

For each migrated release, we also need `helm-operator` to not be paying attention when the `HelmRelease` objects are removed. Scale it down again

```shell
kubectl -n flux scale deployment helm-operator --replicas=0 # stop helm-operator
# Merge in the changed `HelmRelease` into the main repo
flux reconcile source git flux-system
flux tree kustomization flux-system # confirm flux has loaded the new helm release
helm list -A # confirm release is still deployed (you should see the revision incremented as helm-controller did an upgrade)
kubectl -n flux scale deployment helm-operator --replicas=1 # start helm-operator again
```

Repeat for every migration step.

## Step 3: Remove `helm-operator`

```shell
kubectl -n flux scale deployment helm-operator --replicas=0 # stop helm-operator
helm uninstall -n flux helm-operator # uninstall helm-operator
kubectl delete ns flux # delete the old namespace
kubectl delete crd helmreleases.helm.fluxcd.io # delete the old CRD
```
