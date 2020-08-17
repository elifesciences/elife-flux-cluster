# eLife k8s/Flux Production Cluster

EKS cluster name: __kubernetes-aws--flux-prod__

Use this git repo to control the cluster state (no `kubectl` or `helm`
cli action needed/wanted).

-   [Flux](https://docs.fluxcd.io) will try to apply any `yaml` file in
    this repo to the cluster
-   [HelmOperator](https://docs.fluxcd.io/projects/helm-operator) allows
    use of helm charts
-   folders have no meaning to cluster, are used to keep things tidy for
    us humans

Cluster infrastructure is defined in [builder](https://github.com/elifesciences/builder) in the [kubernetes-aws section](https://github.com/elifesciences/builder/blob/52d3c002d1246910243a44e88c7d94d26052e104/projects/elife.yaml#L1999).

Admins can configure `kubectl` for this cluster with:

        aws eks update-kubeconfig \
           --name kubernetes-aws--flux-prod \
           --role arn:aws:iam::512686554592:role/kubernetes-aws--flux-prod--AmazonEKSUserRole


Dashboards
==========

- [Kubernetes Dashboard](https://k8s-dashboard.elifesciences.org)
- [Grafana Dashboards](https://grafana.elifesciences.org/dashboards)
- [Prometheus (Metrics)](https://prometheus.elifesciences.org)
- [Alertmanager](https://alertmanager.elifesciences.org)
- [NewRelic](https://one.newrelic.com/launcher/nr1-core.explorer?pane=eyJuZXJkbGV0SWQiOiJlbnRpdHktb3ZlcnZpZXctbmVyZGxldHMuazhzLWNsdXN0ZXItb3ZlcnZpZXctZGFzaGJvYXJkIiwiZW50aXR5SWQiOiJNVFExTVRRMU1YeEpUa1pTUVh4T1FYdzBOREE1TURnd09ESXlOVGMyT0RjeE5UUTUifQ==&sidebars[0]=eyJuZXJkbGV0SWQiOiJucjEtY29yZS5hY3Rpb25zIiwiZW50aXR5SWQiOiJNVFExTVRRMU1YeEpUa1pTUVh4T1FYdzBOREE1TURnd09ESXlOVGMyT0RjeE5UUTUiLCJzZWxlY3RlZE5lcmRsZXQiOnsibmVyZGxldElkIjoiZW50aXR5LW92ZXJ2aWV3LW5lcmRsZXRzLms4cy1jbHVzdGVyLW92ZXJ2aWV3LWRhc2hib2FyZCJ9fQ==&platform[timeRange][duration]=1800000&platform[$isFallbackTimeRange]=true)

The __#cluster-alerts__ slack channel receives alerts from:

- Alertmanager
- Healthchecks.io (monitors Alertmanager heartbeat)

Adding/Editing Deployments
==========================

- flux tries to apply any .yaml file as a k8s resource
- folder structure is only used for humans
- namespaces are managed using .yaml files
- flux will always apply the HEAD of master

Adding Helm Charts
------------------

-   add a `HelmRelease` object, see
    [docs](https://docs.fluxcd.io/projects/helm-operator/en/stable/references/helmrelease-custom-resource/)
-   chart needs to live in public git or helm repo
    -   Flux can update chart version automatically (see [docs](https://docs.fluxcd.io/projects/helm-operator/en/stable/helmrelease-guide/chart-sources/))
    -   see
        [this](https://github.com/marketplace/actions/helm-publisher)
        github action if you need to publish your chart
-   Flux can [automatically update
    images](https://docs.fluxcd.io/en/1.19.0/references/helm-operator-integration/)
    in your chart
    -   checks image registry every 5 minutes
    -   `HelmRelease` needs to include `repository` and `tag` info
    -   Flux is
        [opinionated](https://docs.fluxcd.io/en/1.19.0/references/helm-operator-integration/#automated-image-detection)
        about `image` location in chart

Debugging
--------
- [k8s dash](https://k8s-dashboard.elifesciences.org/clusters/local)
- [Flux logs](https://k8s-dashboard.elifesciences.org/clusters/local/namespaces/flux/deployments/flux/logs)
- [HelmOperator logs](https://k8s-dashboard.elifesciences.org/clusters/local/namespaces/flux/deployments/helm-operator/logs)
- [State of all Canaries](https://k8s-dashboard.elifesciences.org/clusters/local/namespaces/_all/canaries?)

Services available on the Cluster
=================================

- __nginx-ingress__ ([docs](https://kubernetes.github.io/ingress-nginx/))
  - provides SSL termination
  - `host` entries ending in `.elifesciences.org` will be added to our zone by ExternalDNS
- __PrometheusOperator__ ([docs/monitoring-alerting](docs/monitoring-alerting.md))
  - cluster also instrumented for NewRelic
  - Logs get dumped to Loggly
- __oauth2-proxy__  ([docs/oauth-proxy](docs/oauth-proxy.md))
  - limit access to elifesciences github org
- __SealedSecrets__ ([docs/sealed-secrets.md](docs/sealed-secrets.md))
  - encrypt secrets for safe storage in this repo
- __Flagger__ ([docs/flagger](docs/flagger.md))
  - progressive deployments (Canary/Blue-Green)
  - gating deployments with acceptance and loadtests

Administration
==============

- [Bootstrapping the cluster](docs/bootstrapping.md)
- [Upgrading EKS/Worker Nodesl](docs/upgrading-eks.md)
- [Debugging/Common Fixes](docs/admin-notes.md)