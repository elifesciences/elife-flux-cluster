helm-operator doesn't play nice with being managed as a `HelmRelease`.

- [notes from trying on test-cluster](https://github.com/hivereview/thehive/issues/283)
- [other peoples issue](https://github.com/fluxcd/helm-operator/issues/465)

Follow releases of the [helm-operator repo](https://github.com/fluxcd/helm-operator) and manually upgrade using `helm` v3:

1. `helm repo add fluxcd https://charts.fluxcd.io` if you haven't previously added the repo to your machine
2. `helm repo update`
3. run the same `helm upgrade` command as during [bootstrapping](./bootstrapping.md)  
   (only using `--reuse-values` didn't work)
