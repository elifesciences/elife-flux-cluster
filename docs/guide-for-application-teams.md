# Guide for application teams

Use one of these git repo to control the cluster state (no `kubectl` or `helm` cli action needed/wanted):

- https://github.com/sciety/deployment

Dashboards
==========

- [Kubernetes Dashboard](https://k8s-dashboard.flux-prod.elifesciences.org)
- [Grafana Dashboards](https://grafana.flux-prod.elifesciences.org/dashboards)
- [Alertmanager](https://alertmanager.flux-prod.elifesciences.org)
- [AWS console for the `512686554592` account](https://512686554592.signin.aws.amazon.com/)

The __#cluster-alerts__ slack channel receives alerts from:

- Alertmanager
- Healthchecks.io (monitors Alertmanager heartbeat)

Troubleshooting
===============

When the existing dashboards do not given enough insight, or you need to perform one-off actions on the cluster, `kubectl` access can be set up with:

```
aws eks update-kubeconfig --name kubernetes-aws--flux-prod
```

[Access can be granted](https://github.com/elifesciences/kubernetes-cluster-provisioning/blob/main/clusters/flux-prod/main.tf#L79) by the platform team, upon request.

Adding/Editing Kubernetes manifests
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
    -   Add a [policy marker](https://fluxcd.io/docs/guides/image-update/#configure-image-update-for-custom-resources) to tell Flux how to update the yaml files
  
Managing persistence
--------------------

- `PersistentVolumes` will automatically fulfill the `PersistentVolumeClaims` created by the respective application teams.
  - `storageClass` needs to be specified for all `PersistentVolumeClaims`.
  - `storageClass` value should be team-specific, for cost tracking purposes (e.g. `sciety-gp3`).
- Direct changes to `PersistentVolumes` by any means other than `PersistentVolumeClaims` must only be done by the platform team.

Provide a secret to an application
----------------------------------

### Via AWS Secrets Manager

1. Store the secret in [AWS Secrets Manager](https://us-east-1.console.aws.amazon.com/secretsmanager/listsecrets?region=us-east-1) under a team-based prefix such as `sciety-team/*`.
1. Create an [`ExternalSecret`](https://external-secrets.io/latest/api/spec/#external-secrets.io/v1beta1.ExternalSecret) manifest to pull the secret into the cluster, in the form of a Kubernetes [`Secret`](https://kubernetes.io/docs/concepts/configuration/secret/) managed by the platform.

Kubernetes resources can use the secret:

- directly in workloads e.g. via an [environment variable](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#environment-variables)
- by receiving its value as an [Helm release value](https://fluxcd.io/flux/components/helm/helmreleases/#values-references)


Provision managed databases
===========================

Use the [ACK RDS operator](https://aws-controllers-k8s.github.io/community/docs/tutorials/rds-example/#deploy-database-instances), which is available in the cluster.

```yaml
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBInstance
metadata:
  name: sciety-demo
  namespace: sciety
spec:
  allocatedStorage: 20
  dbInstanceClass: db.t4g.micro
  dbInstanceIdentifier: sciety-demo
  engine: postgres
  engineVersion: "12"
  masterUsername: "postgres"
  masterUserPassword:
    name: demo-database
    key: password
  vpcSecurityGroupIDs:
    - sg-0a04b1c8433227e63
  dbSubnetGroupName: elife-flux-prod-ack-rds-controller-all-dbs
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: demo-database
  namespace: sciety
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: secret-store
    kind: ClusterSecretStore
  target:
    name: demo-database
    creationPolicy: Owner
  dataFrom:
  - extract:
      key: sciety-team/demo-database
```

This depends on a secret existing in AWS Secrets Manager with the name `sciety-team/demo-database` with a _Secret key_ of `password`.

To extract and provide non-secret connection details to the application we suggest you use [FieldExport](https://aws-controllers-k8s.github.io/community/docs/tutorials/rds-example/#connect-to-database-instances).


Services available on the Cluster
=================================

- __nginx-ingress__ ([docs](https://kubernetes.github.io/ingress-nginx/))
  - provides SSL termination
  - `host` entries ending in `.elifesciences.org` will be added to our zone by ExternalDNS
- __cert-manager with letsencrypt__ ([docs/letsencrypt](docs/letsencrypt.md))
  - obtain letsencrypt SSL certs via ingress definitions
- __VictoriaMetrics Operator__ ([docs/monitoring-alerting](docs/monitoring-alerting.md))
- __oauth2-proxy__  ([docs/oauth-proxy](docs/oauth-proxy.md))
  - limit access to elifesciences github org
- __ExternalSecrets Operator__
  - pulls in secrets from storage easily accessible to the application teams
- __SealedSecrets__ ([docs/sealed-secrets.md](docs/sealed-secrets.md))
  - encrypt secrets for safe storage in this repo
- __VictoriaLogs__
  - Stores logs for services in cluster, is queriable from Grafana as a data source.
- __Percona Server for MongoDB operator__
  - Used to run a MongoDB cluster, with support for automated backup, recovery and upgrades.
  - Deployed in "cluster-wide" mode. Each namespace can deploy a database, for example using a [Helm chart](https://github.com/percona/percona-helm-charts/blob/main/charts/psmdb-db/README.md).
