# Guide for application teams

Use one of these git repo to control the cluster state (no `kubectl` or `helm` cli action needed/wanted):

- https://github.com/sciety/deployment

Dashboards
==========

- [Kubernetes Dashboard](https://k8s-dashboard.elifesciences.org)
- [Grafana Dashboards](https://grafana.elifesciences.org/dashboards)
- [Prometheus (Metrics)](https://prometheus.elifesciences.org)
- [Alertmanager](https://alertmanager.elifesciences.org)

The __#cluster-alerts__ slack channel receives alerts from:

- Alertmanager
- Healthchecks.io (monitors Alertmanager heartbeat)

Adding/Editing Deployments
==========================

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

Services available on the Cluster
=================================

- __nginx-ingress__ ([docs](https://kubernetes.github.io/ingress-nginx/))
  - provides SSL termination
  - `host` entries ending in `.elifesciences.org` will be added to our zone by ExternalDNS
- __cert-manager with letsencrypt__ ([docs/letsencrypt](docs/letsencrypt.md))
  - obtain letsencrypt SSL certs via ingress definitions
- __PrometheusOperator__ ([docs/monitoring-alerting](docs/monitoring-alerting.md))
- __oauth2-proxy__  ([docs/oauth-proxy](docs/oauth-proxy.md))
  - limit access to elifesciences github org
- __SealedSecrets__ ([docs/sealed-secrets.md](docs/sealed-secrets.md))
  - encrypt secrets for safe storage in this repo
- __Loki__
  - Stores logs for services in cluster, is queriable from Grafana as a data source.
- __Percona Server for MongoDB operator__
  - Used to run a MongoDB cluster, with support for automated backup, reconvery and upgrades.
  - Deployed in "cluster-wide" mode. Each namespace can deploy it's own cluster of pods from the central operator.
