
#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify an external-secrets git reference to get the CRDs'
    echo "e.g. \`$0 0.16.1\`"
    exit 1
fi

cd $(dirname $0)

curl -sL https://raw.githubusercontent.com/kubernetes-sigs/external-dns/refs/tags/external-dns-helm-chart-$1/charts/external-dns/crds/dnsendpoints.externaldns.k8s.io.yaml  > dnsendpoints.externaldns.k8s.io.yaml
