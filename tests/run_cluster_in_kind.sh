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
kind create cluster --name "$name" --image=kindest/node:v1.27.3

# install kwok into cluster
kubectl kustomize $tests_path/kwok/deploy_config | kubectl apply -f -
kubectl wait deployment -n kube-system kwok-controller --timeout=60s --for condition=Available=True

# Install Flux with toleration to run controllers on the real node
kubectl create ns flux
# make sure flux components get installed, with additional components
flux install --components-extra="image-reflector-controller,image-automation-controller" --toleration-keys=realnode

# taint the current node to not schedule workloads by default
kubectl taint node "$name-control-plane" realnode=true:NoSchedule
# Install kwok nodes to run "workloads" on
kubectl apply -f $tests_path/kwok/1_large_simulated_node.yaml



# Preinstall
# some components require a secret ahead of deployment
kubectl create ns monitoring
# Install cluster stuff and wait
flux create source git flux-system --url="$repo" --branch="$branch"
flux create kustomization flux-system --source=flux-system --path="$test_kustomization_path"
kubectl wait kustomizations.kustomize.toolkit.fluxcd.io --for=condition=ready --timeout=1m -n flux-system flux-system
