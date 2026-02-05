
Monitoring and Alerting
=======================

This document only covers the VictoriaMetrics Operator. It is designed to be compatible with PrometheusOperator, including with the PrometheusOperator CRDs


## Metrics

-   instrument your app and expose a metrics endpoint
    [(docs)](https://prometheus.io/docs/instrumenting/clientlibs/)

-   define metric endpoints as
    [ServiceMonitor](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md#related-resources)
    objects

-   VictoriaMetrics will add all ServiceMonitors in cluster

## Grafana Dashboards

-   add a `ConfigMap` containing the dashboard’s json

-   add the `grafana_dashboard: "1` label

-   in the future maybe switch to something like
    [grafana-operator](https://github.com/integr8ly/grafana-operator)

## Alertmanager

-   add a `PrometheusRule` object

-   give it an `app` label and add this to the
    `prometheusSpec.ruleSelector.matchExpression`

-   [operator
    docs](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/alerting.md)
    on alerting

-   alerts are sent to the \#cluster-alerts channel in elifesciences slack
