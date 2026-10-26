# Dash0 alerting gaps compared to VictoriaMetrics

Remaining work to bring the Dash0 checks (`system/dash0/checks/`) up to the coverage of the
VictoriaMetrics alerts, before VictoriaMetrics alerting is retired.

VictoriaMetrics coverage compared against:
- `victoria-metrics-k8s-stack` 0.78.0 default rules (`system/victoriametrics/release.yaml`)
- `system/monitoring/alertrules-misc.yaml`
- `system/monitoring/alerts/` (OpenSearch, cert-manager)
- `kustomizations/monitoring/flux/flux-alert-rules.yaml`
- `system/temporal/alerts.yaml`

## Done

### 1. Checks for missing metric sources

`MetricSourceMissing` in `system/dash0/checks/alerting-health.yaml` fires when cert-manager,
external-dns, external-secrets or Traefik metrics stop arriving. Without it the checks built
on those metrics go silent instead of firing.

Before pushing:
- [ ] Confirm each metric returns data in Dash0 today, or the check fires as soon as it syncs:
  - `certmanager_certificate_expiration_timestamp_seconds`
  - `external_dns_controller_last_sync_timestamp_seconds`
  - `externalsecret_status_condition`
  - `traefik_entrypoint_requests_total`
- [ ] Confirm a check with no `dash0-threshold-*` annotations counts as critical when it fires,
  so it reaches the notification channel.

## To do

### 2. `kube-system` and `temporal` are not monitored by Dash0

- **kube-system**: coredns, aws-node, kube-proxy and ebs-csi are invisible (see the note in
  `cluster-survival.yaml`). VictoriaMetrics covers them via `TargetDown` and the
  DaemonSet/Deployment rules. Dash0 only sees side effects (pods stuck Pending, ingress errors).
- **temporal**: the namespace has `dash0.com/enable: "false"`, so its workloads and PXC database
  have no checks.
  - `NewCertificateAuthorityIssued` (`system/temporal/alerts.yaml`) cannot be ported as is: the
    Dash0 filter in `system/dash0/release.yaml` drops `certmanager_certificate_not_before_timestamp_seconds`.

Decision needed: enable these namespaces (cost) or accept symptom-only coverage.

### 3. Failed Jobs and CronJobs are invisible

The filter in `system/dash0/release.yaml` drops all `k8s.job.*` metrics, so there is no
equivalent of `KubeJobFailed` / `KubeJobNotCompleted`.

- [ ] Check whether the team deployment repos (sciety, data-hub, ...) run CronJobs that matter.
- [ ] If so, keep the needed `k8s.job.*` metrics (e.g. failed pods) and add a check.

### 4. No OpenSearch alerts

VictoriaMetrics has 8 (`system/monitoring/alerts/opensearch/prometheus_alerts.yaml`): cluster
RED/YELLOW, disk watermarks, JVM heap, bulk rejections, CPU. Dash0 has none.

- [ ] Check whether `opensearch_*` metrics reach Dash0.
- [ ] Port at least cluster RED/YELLOW and the disk watermark alerts.

### 5. Alert routing does not match VictoriaMetrics

- Dash0 notifies `#test-dash0`, only on critical (`notification-channel.yaml`).
  VictoriaMetrics notifies `#cluster-alerts`.
- VictoriaMetrics also routes `namespace` / `exported_namespace` = `data-hub` to
  `#data-hub-notifications` (`system/victoriametrics/config/alertmanager-values.yaml`).
  Dash0 has no per-team routing.
- These checks only have a degraded threshold, so they never notify:
  `CertificateNotReady`, `ExternalSecretNotSynced`, `ExternalDnsNotSyncing`,
  `FluxReconciliationFailing`, `NodeCpuSaturated`, `NodeMemorySaturated`, `NodeDiskSaturated`,
  `NodeDiskFullOutsidePods`, `PodStorageBeyondRequest`, `ContainerCpuNearLimit`,
  `ContainerMemoryNearLimit`. External integrations therefore only alert once a certificate
  is within 7 days of expiry.

- [ ] Point the channel at `#cluster-alerts` at cutover.
- [ ] Add a data-hub notification channel.
- [ ] Decide whether any degraded-only checks should get a critical threshold.

### 6. No dead man's switch

VictoriaMetrics' `Watchdog` pings healthchecks.io. `ChecksNotEvaluating` cannot detect Dash0
evaluation or notification being down. Lower priority since Dash0 is SaaS, but once it is the
only alerting path nothing would report it going silent.

### 7. Smaller gaps

- `KubeHpaMaxedOut`: KEDA workloads stuck at max replicas lose capacity silently.
- `CertManagerHittingRateLimits`: eventually caught by `CertificateExpiring`, just late.
- `KubePersistentVolumeErrors`: low priority.

## Not worth porting

- Node-exporter extras (clock skew, conntrack, network errors, file descriptors, RAID, systemd):
  low value on short-lived Karpenter nodes.
- Kubelet certificates, `KubeletDown`: managed by EKS.
- VictoriaMetrics self-monitoring (vmagent, vmalert, vmsingle): only needed while it runs.
- `CPUThrottlingHigh`: `ContainerCpuNearLimit` is a reasonable stand-in.
- `KubeDeploymentRolloutStuck`, `KubeStatefulSetUpdateNotRolledOut`: a stuck rollout leaves a
  crash-looping or Pending pod, caught by `ContainerRestarting` or `PodStuckPending`.
