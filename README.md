# eLife k8s/Flux Production Cluster

EKS cluster name: __kubernetes-aws--flux-prod__

Use this git repo to control the cluster state (no `kubectl` or `helm`
cli action needed/wanted).

-   [Flux](https://fluxcd.io/docs/) will try to apply any `yaml` file in
    this repo to the cluster
-   [HelmController](https://fluxcd.io/docs/components/helm/) allows
    use of helm charts
-   We currently have three [Kustomizations](https://fluxcd.io/docs/components/kustomize/) defined: `crds`, `system` and `deployments` (each pointed at the root directory named the same). Only Yaml files found in these folders are loaded, in a dependency order (see "Kustomizations" below)


Cluster infrastructure is defined in [builder](https://github.com/elifesciences/builder) in the [kubernetes-aws section](https://github.com/elifesciences/builder/blob/52d3c002d1246910243a44e88c7d94d26052e104/projects/elife.yaml#L1999).

Admins can configure `kubectl` for this cluster with:

        aws eks update-kubeconfig \
           --name kubernetes-aws--flux-prod \
           --role arn:aws:iam::512686554592:role/kubernetes-aws--flux-prod--AmazonEKSUserRole

Dashboards
==========

- [Kubernetes Dashboard](https://k8s-dashboard.flux-prod.elifesciences.org)
- [Grafana Dashboards](https://grafana.flux-prod.elifesciences.org/dashboards)
- [Alertmanager](https://alertmanager.flux-prod.elifesciences.org)

The __#cluster-alerts__ slack channel receives alerts from:

- Alertmanager
- Healthchecks.io (monitors Alertmanager heartbeat)

How to make a change
====================

- Ensure that you have run `mise install` to get up-to-date dependencies.
- Ensure that you have run `make validate` and it completed correctly.
- Follow [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) for commit messages.
- Add a suffix to the commit message containing the issue e.g. `elifesciences/issues#1234`
- Look at the [GitOps dashboard](https://gitops-dashboard--flux-prod.elifesciences.org/) to see the change being applied.

Adding/Editing Deployments
==========================

Kustomizations
--------------

### Cluster level Kustomizations

- `crds`: Cluster managed CustomResourceDefinitions.
- `system`: Cluster services that are not directly serving production usecases. Some infrastructure components needs CRDs to exist before upgrading, so `infrastructure` kustomization depends on `crds` kustomization
- `deployments`: These are the production services. As these all depend on infrastructure to serve traffic correctly, `system` kustomization is a dependency of this kustomization


- flux tries to apply any .yaml file in the kustomization directories above
- within that root folder, the structure is only used for humans
- namespaces are managed using .yaml files
- flux will always apply the HEAD of master

Each namespace is organised around an application, or an environment for an application, favouring the latter.

### Individual Kustomizations

There are a growing number of kustomizations for apps or system that abstract complexity. We can then deploy them with a [flux Kustomization object](https://fluxcd.io/flux/components/kustomize/kustomization/) from one of the cluster kustomizations above. These kustomizations are stored in `kustomzations/`.

Adding Helm Charts
------------------

-   add a "source" object for the HelmChart (either `HelmRepository`, `GitRepository` or `Bucket` [source type](https://fluxcd.io/docs/components/source/))
-   add a `HelmRelease` object, see
    [docs](https://fluxcd.io/docs/components/helm/helmreleases/)
-   Flux can [automatically update
    images](https://docs.fluxcd.io/en/1.19.0/references/helm-operator-integration/)
    in your chart
    -   Setup an [`ImageRepository`](https://fluxcd.io/docs/components/image/imagerepositories/) to query container registry for tags
    -   Setup an [`ImagePolicy`](https://fluxcd.io/docs/components/image/imagepolicies/) to choose what the latest tag is
    -   Setup an [`ImageUpdateAutomation`](https://fluxcd.io/docs/components/image/imageupdateautomations/) to describe which `GitRepository` object you want flux to update, and which directory
    -   Add a [policy marker](https://fluxcd.io/docs/guides/image-update/#configure-image-update-for-custom-resources) to tell Flux how to update te yaml files

Debugging
--------
- [k8s dash](https://k8s-dashboard.flux-prod.elifesciences.org/clusters/local)
- [Flux logs](https://k8s-dashboard.flux-prod.elifesciences.org/clusters/local/namespaces/flux/deployments/flux/logs)
- [HelmOperator logs](https://k8s-dashboard.flux-prod.elifesciences.org/clusters/local/namespaces/flux/deployments/helm-operator/logs)
- [State of all Canaries](https://k8s-dashboard.flux-prod.elifesciences.org/clusters/local/namespaces/_all/canaries?)

Services available on the Cluster
=================================

- __nginx-ingress__ ([docs](https://kubernetes.github.io/ingress-nginx/))
  - provides SSL termination
  - `host` entries ending in `.elifesciences.org` will be added to our zone by ExternalDNS
- __cert-manager with letsencrypt__ ([docs/letsencrypt](docs/letsencrypt.md))
  - obtain letsencrypt SSL certs via ingress definitions
- __VictoriaMetricsOperator__ ([docs/monitoring-alerting](docs/monitoring-alerting.md))
- __oauth2-proxy__  ([docs/oauth-proxy](docs/oauth-proxy.md))
  - limit access to elifesciences github org
- __SealedSecrets__ ([docs/sealed-secrets.md](docs/sealed-secrets.md))
  - encrypt secrets for safe storage in this repo
- __Loki__
  - Stores logs for services in cluster, is queriable from Grafana as a data source.
- __Percona Server for MongoDB operator__
  - Used to run a MongoDB cluster, with support for automated backup, reconvery and upgrades.
  - Deployed in "cluster-wide" mode. Each namespace can deploy it's own cluster of pods from the central operator.

Administration
==============

- [Upgrading infrastructure services](docs/infra-updates.md)
- [Adding a new application team](docs/new-application-team.md)
- [Bootstrapping the cluster](docs/bootstrapping.md)
- [Upgrading EKS/Worker Nodesl](docs/upgrading-eks.md)
- [Debugging/Common Fixes](docs/admin-notes.md)
