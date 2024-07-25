
Bootstrapping the cluster to use flux
=====================================

This only needs to be done upon creation of the cluster.

This follows [flux
get-started for github](https://fluxcd.io/docs/installation/#github-and-github-enterprise).

1.  Configure your `kubectl` using your aws credentials.

        aws eks update-kubeconfig --name kubernetes-aws--flux-prod

2.  Create/locate a [personal access token](https://github.com/settings/tokens), Install flux with all controllers on the cluster linked to this repo

        export GITHUB_TOKEN=<your-token>

        flux bootstrap github --owner=elifesciences --repository=elife-flux-cluster --path=clusters/flux-prod --components-extra=image-reflector-controller,image-automation-controller --read-write-key --branch master

3. Restore sealed-secret master key from backup
