
(Automated) Updates of Infrastructure Services
==============================================

- all Helm Charts in `system` shall be version pinned
- non-HelmRelease deplys shall have their image versions pinned

- All infrastructure services shall be upgraded manually after testing on test-cluster

Update Process
--------------

- renovatebot checks for updates every hour
- renovatebot opens PR if new chart version is available
  - pipeline checks get executed and `assignees` get assigned to PR

Upgrades to critical services should be tested on [elife-flux-test](https://github.com/elifesciences/elife-flux-test).
The services here also have renovatebot configured.


How to Pin
----------

### HelmRelease

- ideally use Helm repos as chart source
- if not possible, use git as chart source but pin to specific ref
- check if chart default values point to specific image tag
- if not: investigate other way to pin and autodetect upgrades

```
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: sealed-secrets
  namespace: infra

spec:
  interval: 5m
  releaseName: infra-sealed-secrets
  chart:
    spec:
      chart: sealed-secrets
      version: 2.1.4
      sourceRef:
        kind: HelmRepository
        name: sealed-secrets
```

See [flux v2 docs](https://fluxcd.io/docs/components/helm/helmreleases/) for further documentation on `HelmReleases`.


### Kubernetes Deployments

- use specific image tag instead of `latest`

```
apiVersion: apps/v1
kind: Deployment
  ...
spec:
  template:
    spec:
      containers:
      - name: kube-web-view
        image: hjacobs/kube-web-view:20.6.0
  ...
```

### Renovatebot settings

- renovatebot is configured via `renovate.json`
- `HelmRelease` files are supported natively, but the renovate config has not been migrated
- [current solution](https://kubernetes-charts.storage.googleapis.com/) is to use the regex functionality
- all github usernames in `assignees` will be assigned PRs

When adding services to `system`:

- add chart name to `packageNames`
- add new `PackageRules` section if needed `registryUrls` entry not present
- set `automerge` flag depending on type of service
