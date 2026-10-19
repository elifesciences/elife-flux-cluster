# Dash0 approach

## What gets shipped

- enable metrics across all namespaces by default
  - disable namespaces using `dash0.com/enable: "false"` label on namespace
  - filter out costly metrics not used for checks or spelunking with `monitoringTemplate.spec.filter`
  - any remaining superfluous metrics are excluded using spam filters (dash0 clickops)
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

Checks and alerts are managed as IaC. Dashboards are managed via clickops.

### Areas to alert on

- cluster survival
  - alerting pipeline broken (watchdog)
  - Node not ready or has otherwise become unresponsive
  - daemon set unhappy
  - Pods failing to schedule
  - bottleneck services e.g. kyverno, traefik unhealthy
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
