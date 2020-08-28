
(Automated) Updates of Infrastructure Services
==============================================

- all Helm Charts in `system` shall be version pinned
- non-HelmRelease deplys shall have their image versions pinned

- mission critical services shall be upgraded manually after testing on test-cluster
- other services should be upgraded automatically using renovatebot

Critical Services
-----------------

Defined as services whose outage leads can lead to production traffic not being served.

- `ingress-nginx`
- `external-dns`

Update Process
--------------

- renovatebot checks for updates every hour
- renovatebot opens PR if new chart version is available
  - pipeline checks get executed
  - if checks pass and `automerge: true`  
    -> renovatebot merges during next run
  - if checks fail  
    OR check pass and `automerge: false`  
    -> `assignees` get assigned to PR

Upgrades to critical services should be tested on [test-cluster](https://github.com/elifesciences/elife-flux-test).
The services here also have renovatebot configured.


How to Pin
----------

### HelmRelease

- ideally use Helm repos as chart source
- if not possible, use git as chart source but pin to specific ref
- check if chart default values point to specific image tag  
  if not: investigate other way to pin and autodetect upgrades

```
apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: sealed-secrets
  namespace: infra
spec:
  releaseName: sealed-secrets
  chart:
    repository: https://kubernetes-charts.storage.googleapis.com/
    name: sealed-secrets
    version: 1.10.3
```

See [HelmOperator chart sources docs](https://docs.fluxcd.io/projects/helm-operator/en/stable/helmrelease-guide/chart-sources/) for further documentation on `HelmReleases`.


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
- `HelmRelease` files aren't [yet](https://github.com/renovatebot/renovate/issues/5984) supported 'natively'
- [current solution](https://kubernetes-charts.storage.googleapis.com/) is to use the regex functionality
- all github usernames in `assignees` will be assigned failed and non-automerged PRs

When adding services to `system`:

- add chart name to `packageNames`
- add new `PackageRules` section if needed `registryUrls` entry not present
- set `automerge` flag depending on type of service
