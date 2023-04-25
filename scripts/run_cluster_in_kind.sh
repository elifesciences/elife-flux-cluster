#!/bin/bash
set -e

name="elife-flux-cluster"
repo="https://github.com/elifesciences/elife-flux-cluster"
test_kustomization_path="./clusters/end-to-end-tests"

# if a param is specified, update the flux-system source branch to that
branch=${1:-master}

echo "Building KinD cluster using '$branch' branch"

kind delete cluster --name "$name"
kind create cluster --name "$name" --image=kindest/node:v1.25.8

# install kwok into cluster
kubectl kustomize scripts/kwok/deploy_config | kubectl apply -f -
kubectl wait deployment -n kube-system kwok-controller --timeout=60s --for condition=Available=True

# Install Flux with toleration to run controllers on the real node
kubectl create ns flux
# make sure flux components get installed, with additional components
flux install --components-extra="image-reflector-controller,image-automation-controller" --toleration-keys=realnode

# taint the current node to not schedule workloads by default
kubectl taint node "$name-control-plane" realnode=true:NoSchedule
# Install kwok nodes to run "workloads" on
kubectl apply -f scripts/kwok/1_large_simulated_node.yaml



# Install cluster stuff and wait
flux create source git flux-system --url="$repo" --branch="$branch"
flux create kustomization flux-system --source=flux-system --path="$test_kustomization_path"
kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=1m -n flux-system flux-system

# Test all kustomizations have reconciled
kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=10m -n flux-system crds
kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=10m -n flux-system system
kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=10m -n flux-system deployments

# Test all system resources have "deployed"
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n autoscaler           cluster-autoscaler
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n infra                sealed-secrets
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n infra                ingress-nginx
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n infra                cert-manager
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n infra                external-dns
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n infra                oauth2-proxy
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n kube-system          descheduler
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n monitoring           metrics-server
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n logging              loki-stack
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n monitoring           newrelic
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n db-operator-system   psmdb-operator
kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n monitoring           prometheus-stack

kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=5m -n monitoring    monitoring-flux

# Test all deployments
# kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n data-hub data-hub--prod
# kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n data-hub data-hub--stg
# kubectl wait helmreleases.helm.toolkit.fluxcd.io --for=condition=ready --timeout=3m -n data-hub data-hub--test
# kubectl wait deployment --for=condition=Available --timeout=3m -n basex-validator      basex-validator--prod
# kubectl wait deployment --for=condition=Available --timeout=3m -n data-hub             data-hub-api--prod
# kubectl wait deployment --for=condition=Available --timeout=3m -n data-hub             data-hub-api--stg
# kubectl wait deployment --for=condition=Available --timeout=3m -n data-hub             sciety-labs--prod
# kubectl wait deployment --for=condition=Available --timeout=3m -n data-hub             sciety-labs--stg
# kubectl wait deployment --for=condition=Available --timeout=3m -n data-hub             test-ftpserver
# kubectl wait deployment --for=condition=Available --timeout=3m -n epp--prod            epp-client
# kubectl wait deployment --for=condition=Available --timeout=3m -n epp--prod            epp-image-server
# kubectl wait deployment --for=condition=Available --timeout=3m -n epp--prod            epp-server
# kubectl wait deployment --for=condition=Available --timeout=3m -n epp--prod            epp-storybook
# kubectl wait deployment --for=condition=Available --timeout=3m -n epp--staging         epp-client
# kubectl wait deployment --for=condition=Available --timeout=3m -n epp--staging         epp-image-server
# kubectl wait deployment --for=condition=Available --timeout=3m -n epp--staging         epp-server
# kubectl wait deployment --for=condition=Available --timeout=3m -n epp--staging         epp-storybook
# kubectl wait deployment --for=condition=Available --timeout=3m -n peerscout            peerscout--prod
# kubectl wait deployment --for=condition=Available --timeout=3m -n peerscout            peerscout--stg
kubectl wait deployment --for=condition=Available --timeout=3m -n podinfo              podinfo--prod
