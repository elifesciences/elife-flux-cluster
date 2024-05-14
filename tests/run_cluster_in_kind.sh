#!/bin/bash
set -e

name="elife-flux-cluster"
repo="https://github.com/elifesciences/elife-flux-cluster"
test_kustomization_path="./clusters/end-to-end-tests"
tests_path="./tests"

# if a param is specified, update the flux-system source branch to that
branch=${1:-master}

echo "Building KinD cluster using '$branch' branch"

kind delete cluster --name "$name"
kind create cluster --name "$name" --image=kindest/node:v1.28.9

# install kwok into cluster
KWOK_RELEASE=v0.5.1
kubectl apply -f "https://github.com/kubernetes-sigs/kwok/releases/download/${KWOK_RELEASE}/kwok.yaml"
# patch kwok to run on the realnode
kubectl patch deployment -n kube-system kwok-controller -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"realnode","operator":"Equal","value":"true","effect":"NoSchedule"}]}}}}'
kubectl apply -f "https://github.com/kubernetes-sigs/kwok/releases/download/${KWOK_RELEASE}/stage-fast.yaml"
kubectl apply -f "https://github.com/kubernetes-sigs/kwok/releases/download/${KWOK_RELEASE}/metrics-usage.yaml"
kubectl wait deployment -n kube-system kwok-controller --timeout=60s --for condition=Available=True

# Install Flux with toleration to run controllers on the real node
kubectl create ns flux
# make sure flux components get installed, with additional components
flux install --components-extra="image-reflector-controller,image-automation-controller" --toleration-keys=realnode

# Add label to allow cluster-services workloads to select this node
kubectl label node "$name-control-plane" Project="end-to-end-tests"
# taint the current node to not schedule workloads by default
kubectl taint node "$name-control-plane" realnode=true:NoSchedule
# Install kwok nodes to run "workloads" on
kubectl apply -f $tests_path/kwok/1_large_simulated_node.yaml
kubectl apply -f $tests_path/kwok/4_smaller_simulated_nodes.yaml



# Preinstall
# some components require a secret ahead of deployment
kubectl create ns victoriametrics
kubectl create secret generic alerts-urls -n victoriametrics --from-literal=slack-api-url=none --from-literal=healthchecks-io-url=none
# Install cluster stuff and wait
flux create source git flux-system --url="$repo" --branch="$branch"
flux create kustomization flux-system --source=flux-system --path="$test_kustomization_path"
kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=1m -n flux-system flux-system
# Force reconcile of all kustomizations
flux reconcile kustomization crds
flux reconcile kustomization system
flux reconcile kustomization deployments
