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
kind create cluster --name "$name" --image=kindest/node:v1.30.6

# Install Flux with toleration to run controllers on the real node
kubectl create ns flux
# make sure flux components get installed, with additional components
flux install --components-extra="image-reflector-controller,image-automation-controller" --toleration-keys=realnode

# Add label to allow cluster-services workloads to select this node
kubectl label node "$name-control-plane" Project="end-to-end-tests"
# taint the current node to not schedule workloads by default
kubectl taint node "$name-control-plane" realnode=true:NoSchedule



# Install gitops stuff and wait
flux create source git flux-system --url="$repo" --branch="$branch"
flux create kustomization flux-system --source=flux-system --path="$test_kustomization_path"
# Force reconcile of all kustomizations
make reconcile
