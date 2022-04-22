
Bootstrapping the cluster to use flux
=====================================

This only needs to be done upon creation of the cluster.

This follows [flux
get-started for github](https://fluxcd.io/docs/installation/#github-and-github-enterprise).

1.  Configure your `kubectl` using your aws credentials.

        aws eks update-kubeconfig \
           --name kubernetes-aws--flux-prod \
           --role arn:aws:iam::512686554592:role/kubernetes-aws--flux-prod--AmazonEKSUserRole

2.  Create/locate a [personal access token](https://github.com/settings/tokens), Install flux with all controllers on the cluster linked to this repo

        export GITHUB_TOKEN=<your-token>

        flux bootstrap github --owner=elifesciences --repository=elife-flux-cluster --path=clusters/flux-prod --components-extra=image-reflector-controller,image-automation-controller --read-write-key --branch master

3. Restore sealed-secret master key from backup

4. Make kube-proxy metrics accessible to prometheus

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
