#!/bin/bash

# Get current cert-manager chart

chart_name=$(yq '.spec.chart.spec.chart' ../../system/infra/cert-manager/release.yaml)
chart_version=$(yq '.spec.chart.spec.version' ../../system/infra/cert-manager/release.yaml)
chart_repo=$(yq '.spec.url' ../../system/infra/cert-manager/source.yaml)

outputdir=$(mktemp -d)
helm pull --repo "$chart_repo" "$chart_name" --version "$chart_version" --untar --untardir $outputdir
cp $outputdir/cert-manager/templates/crds.yaml ./cert-manager.crds.yaml

rm -R $outputdir
