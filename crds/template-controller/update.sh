#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a template-controller helm chart git reference to get the CRDs'
    echo "e.g. \`$0 0.2.2\`"
    exit 1
fi

cd $(dirname $0)

curl -O https://github.com/kluctl/charts/blob/template-controller-$1/charts/template-controller/crds/templates.kluctl.io_githubcomments.yaml
curl -O https://github.com/kluctl/charts/blob/template-controller-$1/charts/template-controller/crds/templates.kluctl.io_gitlabcomments.yaml
curl -O https://github.com/kluctl/charts/blob/template-controller-$1/charts/template-controller/crds/templates.kluctl.io_gitprojectors.yaml
curl -O https://github.com/kluctl/charts/blob/template-controller-$1/charts/template-controller/crds/templates.kluctl.io_listgithubpullrequests.yaml
curl -O https://github.com/kluctl/charts/blob/template-controller-$1/charts/template-controller/crds/templates.kluctl.io_listgitlabmergerequests.yaml
curl -O https://github.com/kluctl/charts/blob/template-controller-$1/charts/template-controller/crds/templates.kluctl.io_objecthandlers.yaml
curl -O https://github.com/kluctl/charts/blob/template-controller-$1/charts/template-controller/crds/templates.kluctl.io_objecttemplates.yaml
curl -O https://github.com/kluctl/charts/blob/template-controller-$1/charts/template-controller/crds/templates.kluctl.io_texttemplates.yaml
