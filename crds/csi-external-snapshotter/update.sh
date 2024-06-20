#!/bin/bash

# As script to update these manually

if [ -z "$1" ]; then
    echo 'ERROR: specify a kubernetes-csi/external-snapshotter git reference to get the CRDs'
    echo "e.g. \`$0 v6.2.1\`"
    exit 1
fi

cd $(dirname $0)

curl -O https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$1/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshotclasses.yaml
curl -O https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$1/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshotcontents.yaml
curl -O https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$1/client/config/crd/groupsnapshot.storage.k8s.io_volumegroupsnapshots.yaml
curl -O https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$1/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
curl -O https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$1/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
curl -O https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/$1/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
