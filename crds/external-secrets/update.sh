
#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify an external-secrets git reference to get the CRDs'
    echo "e.g. \`$0 v0.9.9\`"
    exit 1
fi

cd $(dirname $0)

curl -sL https://raw.githubusercontent.com/external-secrets/external-secrets/$1/deploy/crds/bundle.yaml > external-secrets.crds.yaml
