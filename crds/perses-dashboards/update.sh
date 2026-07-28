
#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a perses-operator git tag to get the CRD'
    echo "e.g. \`$0 v0.4.0\`"
    exit 1
fi

cd $(dirname $0)

curl -sL https://raw.githubusercontent.com/perses/perses-operator/refs/tags/$1/config/crd/bases/perses.dev_persesdashboards.yaml > perses.dev_persesdashboards.yaml
