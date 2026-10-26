# Dash0 approach

## What gets shipped

- enable metrics across all namespaces by default
  - disable namespaces using `dash0.com/enable: "false"` label on namespace
  - filter out costly metrics not used for checks or spelunking with `monitoringTemplate.spec.filter`
  - any remaining superfluous metrics are excluded using `Dash0SpamFilter` resources in `checks/` (e.g. collector self-monitoring, which bypasses the collector pipeline)
- enable logging across all namespaces by default
  - logs are opt-in per workload via the `dash0.com/log-level` pod label; its value is the minimum severity shipped
- do not use tracing (for now)
  - we can achieve required checks and RED observability using metrics
  - revisit when there is demand for something only traces can solve

## Checks and Alerts

Following dash0 language we configure **checks** based on metrics. Checks **may** be configured to alert.

To be an alert the condition must be:

- resolvable by human action
- indicate current or imminent degradation of user facing service

The distinction between alerts and checks in encoded using dash0 severity.

- **critical** = alert, notified via notification channels filtered on `dash0.failed_check.max_status = critical`
- **degraded** = check, reviewed daily in the Failed Checks view

Rules without thresholds report critical, so they are alerts.
Use `dash0-threshold-degraded` for review-only checks, and add `dash0-threshold-critical` when the same signal becomes an alert at a higher level.

Checks and alerts are managed as IaC with `PrometheusRule` resources.

Until we switch off VictoriaMetrics these live in their own namespace so that dash0 can be configured to ignore existing VictoriaMetrics rules and vice versa.

Dashboards are managed via both clickops and IaC. For IaC we use `PersesDashboard` resources in `dashboards/` (e.g. `sciety-red.yaml`, and `traefik-red.yaml` for any Traefik-routed service). They live in their own `dash0-dashboards` namespace, the only one with `synchronizePersesDashboards` enabled, and show as read-only in Dash0.

### Areas to alert on

- cluster survival
  - alerting pipeline broken (collectors not shipping or exporting, checks not evaluating)
  - Node not ready or has otherwise become unresponsive
  - daemon set unhappy
  - Pods failing to schedule
  - kubelet repeatedly evicting pods (node out of disk or memory)
  - core services e.g. kyverno, traefik unhealthy
- workloads
  - service has no targets or StatefulSet/Deployment with 0 replicas
  - frequent OOM kills
  - long running replica mismatches
  - long running crash loops

### Checks reviewed daily (not alerting) to prevent degradation

- certificate expiry
- Flux Reconciliation failure
- replica mismatches
- crash loops
- resource starvation (CPU, Memory, Disk)
- pod evictions

## Reasons beyond checks to ship metrics

- traefik based
  - RED dashboards
  - error/duration SLOs
  - bandwidth usage
- performance spelunking and right-sizing (container CPU and memory)

## k8s events

`k8s.container.status.*` dominates the datapoints shipped. To be able to easily see the reason for container restarts or pending pods we can use a different approach:

- alert using e.g. `k8s.pod.phase` and `k8s.pod.container.restarts`
- get reason via events shipped as logs

## Notes

- Dash0 rejects check rules whose evaluation interval is too short for the query's time window:
  - windows over 1h10m need an interval of at least 5m
  - windows over 8h10m need an interval of at least 10m

  The interval is set per `PrometheusRule` group, so long-window rules live in their own `*-long-window` group, keeping the 1m default for the rest.
- Use `$var` rather than `${var}` for dashboard variables in `PersesDashboard` queries, so that Flux postBuild substitution leaves them alone.
- Dash0 matches regexes unanchored, so anchor selectors with `^` explicitly.

## read-only Access for Agents

There is a token with ro-access set up in the dash0 org. Configure it as follows:

```
dash0 config profiles create agent-ro --api-url https://api.us-east-1.aws.dash0.com --auth-token xxxxx
dash0 config profiles select agent-ro
```

