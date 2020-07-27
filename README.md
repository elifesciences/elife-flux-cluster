# eLife k8s/Flux Production Cluster


Overview of the Cluster
==========================

EKS cluster name: __kubernetes-aws--flux-prod__

Use this git repo to control the cluster state (no `kubectl` or `helm`
cli action needed/wanted).

-   [Flux](https://docs.fluxcd.io) will try to apply any `yaml` file in
    this repo to the cluster

-   [HelmOperator](https://docs.fluxcd.io/projects/helm-operator) allows
    use of helm charts

-   folders have no meaning to cluster, are used to keep things tidy for
    us humans

Cluster infrastruce is defined in [builder](https://github.com/elifesciences/builder) in the [kubernetes-aws section](https://github.com/elifesciences/builder/blob/52d3c002d1246910243a44e88c7d94d26052e104/projects/elife.yaml#L1999).


Dashboards
----------

- [Kubernetes Dashboard](https://k8s-dashboard.elifesciences.org)
- [Grafana Dashboards](https://grafana.elifesciences.org)
- [Prometheus (Metrics)](https://prometheus.elifesciences.org)
- [Alertmanager](https://alertmanager.elifesciences.org)


Authentication
--------------

[oauth2 proxy](https://oauth2-proxy.github.io/oauth2-proxy/) available to protect services without their own login.

Provides access to all members of elifesciences Github organisation.

Add following annotations to your service’s ingress:

    annotations:
      nginx.ingress.kubernetes.io/auth-url: "https://oauth-proxy.elifesciences.org/oauth2/auth"
      nginx.ingress.kubernetes.io/auth-signin: "https://oauth-proxy.elifesciences.org/oauth2/start?rd=https%3A%2F%2F$host$request_uri"


Monitoring/Alerting
-------------------

Infrastructure (all behind oauth2\_proxy)

-   Prometheus/Grafana/Alertmanager via the [prometheus-operator
    chart](https://github.com/helm/charts/tree/master/stable/prometheus-operator).

-   Kubernetes Dashboard with anonymous access but limited to read only

### Metrics

-   instrument your app and expose a metrics endpoint
    [(docs)](https://prometheus.io/docs/instrumenting/clientlibs/)

-   define metric endpoints as
    [ServiceMonitor](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/getting-started.md#related-resources)
    objects

-   Prometheus will add all ServiceMonitors in cluster

### Dashboards

-   add a `ConfigMap` to the `adm` namespace containing the dashboard’s
    json

-   add the `grafana_dashboard: "1` label

-   see `releases/adm/ingress-nginx-dashboard-main.yaml` for an example

-   in the future maybe switch to something like
    [grafana-operator](https://github.com/integr8ly/grafana-operator)

### Alerts

-   add a `PrometheusRule` object

-   give it an `app` label and add this to the
    `prometheusSpec.ruleSelector.matchExpression`

-   [operator
    docs](https://github.com/coreos/prometheus-operator/blob/master/Documentation/user-guides/alerting.md)
    on alerting

-   alerts are sent to the \#alerts-test channel in elifesciences slack

-   Alertmanager is configured with a secret

    -   see `alertmanager-secret.yaml-template`

    -   too apply:

            # Make sure to insert the webhook urls before applying
            kubectl -n adm delete secret alertmanager-prometheus-operator
            cp alertmanager-secret.yaml-template alertmanager.yaml
            kubectl -n adm create secret generic alertmanager-prometheus-operator --from-file=alertmanager.yaml
            rm alertmanager.yaml

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

-   chart needs to live in public git repo or needs be published

-   see
    [this](https://github.com/marketplace/actions/helm-chart-releaser)
    github action if you need to publish your chart

-   Flux can [automatically update
    images](https://docs.fluxcd.io/en/1.19.0/references/helm-operator-integration/)
    in your chart

    -   checks image registry every 5 minutes

    -   `HelmRelease` needs to include `repository` and `tag` info

    -   Flux is
        [opinionated](https://docs.fluxcd.io/en/1.19.0/references/helm-operator-integration/#automated-image-detection)
        about `image` location in chart

-   Flux will update deployments if chart versions get bumped, but only
    if the chart source is a git repo (see
    [docs](https://docs.fluxcd.io/projects/helm-operator/en/stable/helmrelease-guide/chart-sources/))

Progressive Delivery
====================

The cluster has [Flagger](https://docs.flagger.app/) installed. This can be used for:

- canary style traffic shifting
- blue/Green style promotion
- loadtesting canaries/deploys
- conformance testing with e.g. `helm test`
- automated rollbacks based on webhooks and/or prometheus queries

This behaviour is attached to a specific `Deployment` and `Ingress` object through the creation of `Canary` objects.

### Smoke/Conformance Tests

Flagger provides a set of [hooks to gate rollouts](https://docs.flagger.app/usage/webhooks). Hooks can call a URL or execute commands on the `flagger-loadtester` deployments which comes with `helm`, `bats` and `hey`.

The pattern used for [reviewer](https://github.com/elifesciences/elife-flux-test/blob/master/releases/prod/libero-reviewer.yaml) is:

- bundle browsertests into a container
- declare a k8s job as a helm test hook
- parametrise the job with a target url and test suite to run

When flagger detects a change to the `reviewer--prod` deployments:

- spin up canary
- check if `stg` and `prod` images and chart match
- run acceptance browser tests agains `stg`
- start shifting traffic to canary
- smoketest canary with browsertests
- loadtest public facing url
- rollback if anything fails

### Gotchas

- `name` of `Deployment` has to match its `metadata`
  The default `helm` template uses `name` for the former and `fullname` for the latter which buggers up the `ingress` and `service` definitions created by flagger.
- default analysis metrics expect ingress controlller in same namespace as canary
  Since we have a single central controller living in `adm` we need to use a custom metric template. This hardcodes the namespace as the `templateRef.namespace` only locates the `MetricTemplate` object.
- metric `interval` should be at least `1m`
  Shorter durations lead to empty `rate` values being returned by Prometheus as the windows will only have a single data point.

Useful commands for admins
==========================

If flux is installed to a namespace `fluxctl` needs to be invoked as:

    fluxctl --k8s-fwd-ns flux

### Observing flux state

    fluxctl sync  # forces flux to sync git repo
    fluxctl list-workloads --all-namespaces
    helm list --all-namespaces

    # List all image versions running on cluster
    kubectl get pods --all-namespaces -o=jsonpath='{range .items[*]}{"\n"}{.metadata.name}{":\t"}{range .spec.containers[*]}{.image}{", "}{end}{end}' |
    sort | column -t

### Debugging

    kubectl -n flux logs helm-operator-86b8f67577-wldq5 --follow
    helm -n adm history adm-prometheus-operator -o yaml

If `helm lint` is happy but operator is complaining:

-   copy `values` section from the `HelmRelease` to a `dummy.yaml`

-   run `helm dependency update charts/libero-reviewer`

-   now you can run `helm install --dry-run` or `helm template --debug`

### helm-operator can’t upgrade due to `failed` helm state

Try running a `helm rollback` to get out of the failed state and then
let `helm-operator` do its thing.

Another approach is to manually upgrade the helm chart. See
[faq](https://docs.fluxcd.io/projects/helm-operator/en/stable/faq/#a-helmrelease-is-stuck-in-a-failed-release-state-how-do-i-force-it-through)
and [this
issue](https://github.com/fluxcd/helm-operator/issues/241#issuecomment-578351380).

    helm -n <namespace> list
    helm -n <namespace> -i <release> upgrade --reuse-values <any additional flags> <chart>

### Sniffing packets

If logs aren't sufficient you can use the [sniff kubectl extension](https://github.com/eldadru/ksniff) to dump directly into wireshark or a local file.

Bootstrapping the cluster to use flux
=====================================

This only needs to be done upon creation of the cluster.

This follows [flux
get-started-helm](https://docs.fluxcd.io/en/stable/tutorials/get-started-helm/).

1.  Configure your `kubectl` using your aws credentials.

        aws eks update-kubeconfig \
           --name kubernetes-aws--flux-test \
           --role arn:aws:iam::512686554592:role/kubernetes-aws--flux-test--AmazonEKSUserRole

2.  Install flux and helm-operator on the cluster, link to this repo
    NOTE: make sure to use `helm3`

        kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml

        helm repo add fluxcd https://charts.fluxcd.io

        kubectl create namespace flux

        helm upgrade -i flux fluxcd/flux \
          --set git.url=git@github.com:elifesciences/elife-flux-cluster \
          --set syncGarbageCollection.enabled=true \
         --set prometheus.serviceMonitor.create=true \
         --set prometheus.serviceMonitor.namespace=adm \
          --namespace flux

        helm upgrade -i helm-operator fluxcd/helm-operator \
         --set git.ssh.secretName=flux-git-deploy \
         --set helm.versions=v3 \
         --set statusUpdateInterval="90s" \
         --set resources.limits.memory=1Gi \
         --set resources.requests.memory=500Mi \
         --set resources.requests.cpu=400m \
         --set prometheus.serviceMonitor.create=true \
         --set prometheus.serviceMonitor.namespace=adm \
         --namespace flux

3.  Add flux to repo’s deploy keys

        fluxctl identity --k8s-fwd-ns flux
        # add this as deploy key with push rights to the github repo

4.  Remove privileged PodSecurityPolicy set by EKS

    -   follow [aws
        docs](https://docs.aws.amazon.com/eks/latest/userguide/pod-security-policy.html)
        to remove policy

        -   copy-paste default policy, role and role-binding into yaml

        -   run `kubectl delete -f privileged-podsecuritypolicy.yaml`

    -   check if our PodSecurityPolicy is applied
        (releases/kube-system/podsecuritypolicy.yaml)

            > kubectl get podsecuritypolicies.policy | grep "privileged\|baseline"
            baseline                                                 false   CHOWN,DAC_OVERRIDE,FSETID,FOWNER,MKNOD,NET_RAW,SETGID,SETUID,SETFCAP,SETPCAP,NET_BIND_SERVICE,SYS_CHROOT,KILL,AUDIT_WRITE   RunAsAny   RunAsAny           RunAsAny    RunAsAny    false            configMap,emptyDir,projected,secret,downwardAPI,persistentVolumeClaim,awsElasticBlockStore,azureDisk,azureFile,cephFS,cinder,csi,fc,flexVolume,flocker,gcePersistentDisk,gitRepo,glusterfs,iscsi,nfs,photonPersistentDisk,portworxVolume,quobyte,rbd,scaleIO,storageos,vsphereVolume

            > kubectl get clusterroles.rbac.authorization.k8s.io | grep podsec
            podsecuritypolicy:baseline                                             3m45s


            > kubectl get clusterrolebindings.rbac.authorization.k8s.io | grep podsec
            podsecuritypolicy:authenticated                        3m59s

5.  Make kube-proxy metrics accessible to prometheus

    By default kube-proxy metrics are only accessible on localhost. See
    prometheus operator
    [readme](https://github.com/helm/charts/tree/master/stable/prometheus-operator#kubeproxy)

    -   edit configmap
        `kubectl -n kube-system edit cm kube-proxy-config`

    -   set `metricsBindAddress: 0.0.0.0:10249`

    -   delete all `kube-proxy` pods, they will be recreated with the
        new config

    -   if this leads to kube-version-mismatch set the correct image:

            kubectl set image daemonset.apps/kube-proxy \
              -n kube-system \
              kube-proxy=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/kube-proxy:v1.14.9
