
Monitoring and Alerting
=======================

This document only covers the PrometheusOperator.

The cluster also dumps metrics and logs to NewRelic respectively.


## Prometheus Metrics

-   instrument your app and expose a metrics endpoint
    [(docs)](https://prometheus.io/docs/instrumenting/clientlibs/)

-   define metric endpoints as
    [ServiceMonitor](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md#related-resources)
    objects

-   Prometheus will add all ServiceMonitors in cluster

## Grafana Dashboards

-   add a `ConfigMap` to the `adm` namespace containing the dashboard’s
    json

-   add the `grafana_dashboard: "1` label

-   see `releases/adm/ingress-nginx-dashboard-main.yaml` for an example

-   in the future maybe switch to something like
    [grafana-operator](https://github.com/integr8ly/grafana-operator)

## Alertmanager

-   add a `PrometheusRule` object

-   give it an `app` label and add this to the
    `prometheusSpec.ruleSelector.matchExpression`

-   [operator
    docs](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/alerting.md)
    on alerting

-   alerts are sent to the \#alerts-test channel in elifesciences slack

-   Alertmanager is configured with a secret

    -   see `namespaces/monitoring/secrets/alertmanager-secret.template`

    -   insert webhook urls before applying

            cd namespaces/monitoring/secrets
            cp alertmanager-secret.template /tmp/alertmanager.yaml
            kubectl -n monitoring create secret generic alertmanager-prometheus-operator \
                --from-file=/tmp/alertmanager.yaml \
                --dry-run=client \
                -o yaml > /tmp/alertmanager-secret.yaml
            kubeseal \
                --controller-namespace infra --controller-name sealed-secrets \
                --format=yaml < /tmp/alertmanager-secret.yaml > alertmanager.yaml \
                && rm /tmp/alertmanager*
