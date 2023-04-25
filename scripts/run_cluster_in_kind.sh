#!/bin/bash
set -e


# if a param is specified, update the flux-system source branch to that
branch=${1:-master}

echo "Building KinD cluster using '$branch' branch"

kind delete cluster --name "elife-flux-test"
kind create cluster --name "elife-flux-test" --image=kindest/node:v1.25.8

# install kwok into cluster
kubectl kustomize scripts/kwok/deploy_config | kubectl apply -f -
kubectl wait deployment -n kube-system kwok-controller --timeout=60s --for condition=Available=True

# Install Flux with toleration to run controllers on the real node
kubectl create ns flux
# make sure flux components get installed, with additional components
flux install --components-extra="image-reflector-controller,image-automation-controller" --toleration-keys=realnode

# taint the current node to not schedule workloads by default
kubectl taint node elife-flux-test-control-plane realnode=true:NoSchedule
# Install kwok nodes to run "workloads" on
kubectl apply -f scripts/kwok/1_large_simulated_node.yaml



# Install cluster stuff and wait
flux create source git flux-system --url=https://github.com/elifesciences/elife-flux-test --branch="$branch"
flux create kustomization flux-system --source=flux-system --path=./clusters/end-to-end-tests
kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=1m -n flux-system flux-system

# Test all kustomizations have reconciled
kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=10m -n flux-system crds
kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=10m -n flux-system system
kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=10m -n flux-system deployments

# Test all system resources have "deployed"
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n autoscaler         cluster-autoscaler
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n infra             sealed-secrets
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n infra              ingress-nginx
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n infra              cert-manager
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n infra              external-dns
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n infra              oauth2-proxy
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n kube-system        descheduler
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n monitoring         metrics-server
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n logging            loki-stack
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n crossplane-system  crossplane
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n db-operator-system psmdb-operator
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n monitoring         prometheus-stack

kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n monitoring monitoring-flux

# Test all deployments
kubectl wait deployment --for=condition=Available --timeout=5m -n podinfo    podinfo--stg
