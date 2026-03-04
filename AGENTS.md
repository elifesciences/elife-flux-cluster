# AGENTS.md — eLife Flux Cluster

This repository manages the eLife production Kubernetes cluster (`kubernetes-aws--flux-prod`) via GitOps using Flux CD v2. **All cluster changes are made by committing YAML to this repo** — no direct `kubectl` or `helm` commands are wanted on the live cluster.

## Repository Layout

```
clusters/          Flux Kustomization definitions (what Flux watches and in what order)
crds/              Custom Resource Definitions (installed first, operators depend on these)
system/            Cluster-wide infrastructure services (traefik, cert-manager, monitoring, databases, etc.)
nodes/             Karpenter NodePools and EKS ClusterClass definitions
policies/          Kyverno policies and topology spread constraints
deployments/       Application deployments, namespaced per environment (epp/prod, epp/staging, etc.)
kustomizations/    Reusable Kustomize overlays composed into deployments
teams/             Per-team infrastructure (node pools, storage classes, external repo sync)
docs/              Detailed guides for specific subsystems
scripts/           validate.sh, node drain/terminate helpers
```

**Load order** (Flux dependency chain): `crds` → `nodes`, `policies` → `system` → `deployments`

## Prerequisites

```bash
mise install          # installs kubectl, flux, kustomize, helm, yq, kubeconform, awscli
aws eks update-kubeconfig --name kubernetes-aws--flux-prod
make validate         # must pass before pushing
```

## Workflow for Every Change

1. Make the YAML change in the appropriate directory.
2. Run `make validate` — this runs `scripts/validate.sh` which builds all kustomize overlays and validates with kubeconform.
3. Commit using [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) — see examples below.
4. Push to `master`. Flux reconciles every minute.
5. Monitor progress at the [GitOps dashboard](https://gitops-dashboard--flux-prod.elifesciences.org/) or with `make reconcile`.

Commit message conventions used in this repo:
```
deploy(traefik): Set resource requests after observation
feat(kustomizations/epp): Add support for IIIF server envvar
fix(epp/prod): Add missing namespace
chore(deps): update helm release cert-manager to v1.17.0
```
Append `elifesciences/issues#NNNN` when there is a related issue.

---

## Common Tasks

### Adjust resource requests on a system service

Resource requests are tuned after observing actual usage in Grafana/VictoriaMetrics.

1. Open `system/{service}/release.yaml` (for Helm-managed services) or the Deployment manifest.
2. Edit the `resources.requests` (and optionally `limits`) under the relevant Helm values key or container spec.
3. Validate and commit:
   ```
   deploy(victoriametrics): Adjust resource requests after observation
   ```

Example — editing a HelmRelease values block:
```yaml
# system/victoriametrics/release.yaml
spec:
  values:
    vmstorage:
      resources:
        requests:
          cpu: 500m
          memory: 4Gi
```

### Add a new cluster-wide infrastructure service

See `docs/infra-updates.md` for the full guide. In brief:

1. Create `system/{service-name}/` with these files:
   - `namespace.yaml` — Kubernetes Namespace
   - `source.yaml` — HelmRepository (or GitRepository/Bucket)
   - `release.yaml` — HelmRelease with a **pinned** chart version
   - `kustomization.yaml` — Kustomize manifest listing the above files
2. Add the directory to the parent kustomization: `system/clusters/flux-prod/kustomization.yaml`
3. Add a Renovatebot rule in `renovate.json` so chart versions are tracked automatically.
4. Pin all image tags — never use `latest`.

Template `release.yaml`:
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-service
  namespace: my-service
spec:
  interval: 5m
  chart:
    spec:
      chart: my-chart
      version: 1.2.3         # always pin
      sourceRef:
        kind: HelmRepository
        name: my-repo
        namespace: my-service
  values:
    # override chart defaults here
```

### Update CRDs for an existing operator

Renovatebot detects new operator versions and opens a PR updating the HelmRelease in `system/`. CRDs must be updated to match before the PR is merged — the `crds/` Kustomization is applied before `system/`, so they need to land together or ahead of the operator upgrade.

1. Check out the Renovatebot branch locally.
2. Run the CRD update script from the repo root:
   ```bash
   ./crds/update_all.sh
   ```
   This script reads the version already set in each HelmRelease file on the branch and downloads the matching CRDs from upstream for every tracked operator.
3. Commit the CRD changes:
   ```
   deploy(crds/psmdb-operator): Update CRDs after #4154
   ```
4. Push to the Renovatebot branch and merge the PR on GitHub.

`crds/update_all.sh` covers all operators that have CRDs tracked here. Each operator also has its own `crds/{operator}/update.sh` that can be run individually if you only need to update one.

### Add a new application team

See `docs/new-application-team.md` for the complete checklist. Summary:

1. Decide on a namespace name (e.g., `myteam`).
2. Create `teams/myteam/` containing:
   - `nodepool.yaml` — Karpenter NodePool (spot + on-demand fallback), with a taint matching the namespace
   - `al2023nodeclass.yaml` — EC2NodeClass defining AMI, instance profile, tags
   - `storageclass.yaml` — team-specific StorageClass for cost tracking (e.g., `myteam-gp3`)
   - `volumesnapshotclass.yaml` — VolumeSnapshotClass
   - `deployment-sync.yaml` — GitRepository + Flux Kustomization pointing at the team's external deployment repo
   - `team-admin-group.yaml` — Kubernetes Group for RBAC
3. Create `clusters/flux-prod/myteam-team.yaml` — a cluster-level Flux Kustomization that depends on `nodes` and `policies`.
4. The team creates a Namespace in their own deployment repo with the annotation:
   ```yaml
   annotations:
     elifesciences.org/default-project: myteam
   ```

Look at `teams/sciety/` as the canonical reference implementation.

### Configure KEDA autoscaling for a deployment

KEDA scales pods based on metrics. Two main patterns:

**HTTPScaledObject** (scale on HTTP request rate, down to zero):
```yaml
apiVersion: http.keda.sh/v1alpha1
kind: HTTPScaledObject
metadata:
  name: my-service
  namespace: myteam--prod
spec:
  hosts:
    - my-service.flux-prod.elifesciences.org
  scaleTargetRef:
    name: my-service
  replicas:
    min: 0
    max: 10
```

**ScaledObject** (scale on VictoriaMetrics query):
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: my-worker
  namespace: myteam--prod
spec:
  scaleTargetRef:
    name: my-worker
  minReplicaCount: 0
  maxReplicaCount: 20
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://vmselect-victoria-metrics.monitoring:8481/select/0/prometheus
        query: sum(queue_depth{namespace="myteam--prod"})
        threshold: "5"
```

When a `ScaledObject` controls replicas, **do not set `spec.replicas`** on the Deployment — remove it or KEDA will fight with it.

### Add or modify a Traefik ingress

Traefik is the cluster ingress controller. All new ingresses should use `ingressClassName: traefik`.

Standard ingress with TLS (cert-manager handles the cert automatically):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-service
  namespace: myteam--prod
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: "infra-elife-oauth@kubernetescrd"  # optional: add SSO
spec:
  ingressClassName: traefik
  rules:
    - host: my-service.flux-prod.elifesciences.org
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 8080
  tls:
    - hosts:
        - my-service.flux-prod.elifesciences.org
      secretName: my-service-tls
```

Hostnames ending in `.elifesciences.org` are automatically registered in DNS by ExternalDNS.

Traefik Middlewares for common patterns live in `system/traefik/`. Reference them as `{namespace}-{name}@kubernetescrd`.

### Add a monitoring alert

Alerting rules live in `system/monitoring/`. VictoriaMetrics evaluates them and routes alerts via Alertmanager.

1. Add or edit a `VMRule` resource under `system/monitoring/`:
   ```yaml
   apiVersion: operator.victoriametrics.com/v1beta1
   kind: VMRule
   metadata:
     name: my-service-alerts
     namespace: monitoring
   spec:
     groups:
       - name: my-service
         rules:
           - alert: MyServiceDown
             expr: up{job="my-service"} == 0
             for: 5m
             labels:
               severity: critical
               namespace: myteam--prod
             annotations:
               summary: "my-service is down"
   ```
2. Alert routing (which Slack channel receives it) is configured in `system/victoriametrics/` — the `VMAlertmanagerConfig` resources define routes matching on labels like `namespace` or `exported_namespace`.
3. Dashboards are managed as ConfigMaps with the label `grafana_dashboard: "1"` — see existing examples in `system/grafana/`.

### Manage secrets

**Preferred: ExternalSecrets** (pulls from AWS Secrets Manager):
```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: my-secret
  namespace: myteam--prod
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: secret-store
    kind: ClusterSecretStore
  target:
    name: my-secret
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: myteam/my-secret     # path in AWS Secrets Manager
```

Force a manual sync: `kubectl annotate es my-secret force-sync=$(date +%s) --overwrite -n myteam--prod`

**Legacy: SealedSecrets** — see `docs/sealed-secrets.md`. Prefer ExternalSecrets for new work.

There is also a reusable kustomization for RDS PostgreSQL secrets: `kustomizations/utils/rds-pg-external-secret/` — parameterise it via `postBuild.substitute` to avoid repeating the ExternalSecret boilerplate across environments.

### Adjust a Karpenter node pool

Node pool definitions live in `nodes/karpenter/` (cluster-wide pools) and `teams/{team}/nodepool.yaml` (team pools).

Common adjustments:
- **CPU/memory limits**: edit `spec.limits.cpu` and `spec.limits.memory`
- **Instance types**: edit `spec.template.spec.requirements` — add/remove instance families or sizes
- **Spot vs on-demand**: separate NodePool resources exist for spot (primary) and on-demand (fallback); the on-demand pool uses a higher `weight`
- **Zone pinning**: add a `topology.kubernetes.io/zone` requirement to restrict to a specific AZ (used for stateful services that need to co-locate with their EBS volumes)

### Deploy a new application

New applications should **not** be added under `deployments/` — that directory contains legacy deployments and is not the pattern to follow.

Instead, follow the team deployment repo model described in "Add a new application team" above. The team manages their own Kubernetes manifests in a separate GitHub repository (e.g. `sciety/sciety-team-deployment`), and this repo only holds the team's infrastructure (node pool, storage class, external repo sync). See `docs/guide-for-application-teams.md` for what the platform provides and how to use it from a team deployment repo.

### Maintaining the legacy EPP deployment

> The EPP deployment under `deployments/epp/` is legacy. Do not use it as a model for new work. It will be migrated to a team deployment repo in the future.

**Environments** (`deployments/epp/`):

| Directory | Namespace |
|-----------|-----------|
| `prod/` | `epp--prod` |
| `staging/` | `epp--staging` |
| `biophysics-colab/` | `epp--biophysics-colab` |
| `previews/` | `epp--previews` |

Each environment is a Flux `Kustomization` referencing shared overlays in `kustomizations/apps/epp/` with environment-specific values injected via `postBuild.substitute`.

**Image automation**: images are updated automatically via `ImageRepository` → `ImagePolicy` → `ImageUpdateAutomation`. Do not manually edit lines containing `# {"$imagepolicy": ...}` — the automation overwrites them. `biophysics-colab` uses an approved-tag policy rather than `master-*`.

**Common changes**:
- *Environment variable*: edit `spec.postBuild.substitute` in `{env}/epp-kustomization.yaml`. If the variable is new, also add the `${variable_name}` placeholder in the relevant file under `kustomizations/apps/epp/`.
- *Resource requests*: add a Kustomize patch in `{env}/` targeting the relevant Deployment. Base manifests are in `kustomizations/apps/epp/{component}/`.
- *KEDA scaling*: edit the `ScaledObject` in `{env}/`. Remove `spec.replicas` from the Deployment when KEDA controls it.
- *MongoDB config*: edit the HelmRelease (`*-database*.yaml`) in `{env}/`. After a chart version change, run `./crds/update_all.sh` on the Renovatebot branch before merging.

**Debugging**:
```bash
make epp-mongodb-prod                                    # port-forward to MongoDB
kubectl get pods -n epp--prod -w                         # watch pod status
flux reconcile kustomization epp--prod -n epp--prod      # force reconciliation
kubectl get imagepolicies,imageupdateautomations -n epp--prod
```

---

## Debugging

| What | Where |
|------|-------|
| Flux reconciliation status | [GitOps dashboard](https://gitops-dashboard--flux-prod.elifesciences.org/) |
| Pod logs, events | [Kubernetes dashboard](https://k8s-dashboard.flux-prod.elifesciences.org) |
| Metrics & dashboards | [Grafana](https://grafana.flux-prod.elifesciences.org/dashboards) |
| Active alerts | [Alertmanager](https://alertmanager.flux-prod.elifesciences.org) / [VMAlert](https://vmalert.flux-prod.elifesciences.org/vmalert/groups) |
| Slack | `#cluster-alerts` |

Force a full Flux reconciliation: `make reconcile`

Watch node pool state: `make watch-nodes`

Get cluster kubeconfig: `aws eks update-kubeconfig --name kubernetes-aws--flux-prod`

---

## Key Conventions

- **Never use `latest` image tags** — always pin to a specific version or digest.
- **Never apply changes directly with `kubectl apply` or `helm upgrade`** — Flux will overwrite them and the change won't be tracked.
- **All versions are tracked by Renovatebot** — when adding a new HelmRelease or image, add a corresponding entry to `renovate.json` so updates are automated.
- **Validate before pushing**: `make validate` runs kustomize build + kubeconform against all overlays.
- **CRDs must be updated before the operator** — commit CRD changes to `crds/` first if the operator upgrade requires it.
- **Resource requests are required** — Kyverno policies enforce that all pods have resource requests set. Set them based on observed usage from Grafana.
