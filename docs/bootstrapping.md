
Bootstrapping the cluster to use flux
=====================================

This only needs to be done upon creation of the cluster.

This follows [flux
get-started-helm](https://docs.fluxcd.io/en/stable/tutorials/get-started-helm/).

1.  Configure your `kubectl` using your aws credentials.

        aws eks update-kubeconfig \
           --name kubernetes-aws--flux-prod \
           --role arn:aws:iam::512686554592:role/kubernetes-aws--flux-prod--AmazonEKSUserRole

2.  Install flux and helm-operator on the cluster, link to this repo
    NOTE: make sure to use `helm3`  
    NOTE: run without `prometheus` lines first, run with them after PrometheusOperator is installed

        kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml

        helm repo add fluxcd https://charts.fluxcd.io

        kubectl create namespace flux

        helm upgrade -i flux fluxcd/flux \
          --set git.url=git@github.com:elifesciences/elife-flux-cluster \
          --set syncGarbageCollection.enabled=true \
         --set prometheus.serviceMonitor.create=true \
         --set prometheus.serviceMonitor.namespace=monitoring \
          --namespace flux

        helm upgrade -i helm-operator fluxcd/helm-operator \
         --set git.ssh.secretName=flux-git-deploy \
         --set helm.versions=v3 \
         --set statusUpdateInterval="90s" \
         --set resources.limits.memory=2Gi \
         --set resources.requests.memory=500Mi \
         --set resources.requests.cpu=400m \
         --set prometheus.serviceMonitor.create=true \
         --set prometheus.serviceMonitor.namespace=monitoring \
         --namespace flux

3.  Add flux to repo’s deploy keys

        fluxctl identity --k8s-fwd-ns flux
        # add this as deploy key with push rights to the github repo

4.  Remove privileged PodSecurityPolicy set by EKS

    -   follow [aws
        docs](https://docs.aws.amazon.com/eks/latest/userguide/pod-security-policy.html)
        to remove policy

        -   copy-paste default policy, role and role-binding into yaml

        -   run `kubectl delete -f privileged-podsecuritypolicy.yaml`

    -   check if our PodSecurityPolicy is applied
        (releases/kube-system/podsecuritypolicy.yaml)

            > kubectl get podsecuritypolicies.policy | grep "privileged\|baseline"
            baseline                                                 false   CHOWN,DAC_OVERRIDE,FSETID,FOWNER,MKNOD,NET_RAW,SETGID,SETUID,SETFCAP,SETPCAP,NET_BIND_SERVICE,SYS_CHROOT,KILL,AUDIT_WRITE   RunAsAny   RunAsAny           RunAsAny    RunAsAny    false            configMap,emptyDir,projected,secret,downwardAPI,persistentVolumeClaim,awsElasticBlockStore,azureDisk,azureFile,cephFS,cinder,csi,fc,flexVolume,flocker,gcePersistentDisk,gitRepo,glusterfs,iscsi,nfs,photonPersistentDisk,portworxVolume,quobyte,rbd,scaleIO,storageos,vsphereVolume

            > kubectl get clusterroles.rbac.authorization.k8s.io | grep podsec
            podsecuritypolicy:baseline                                             3m45s


            > kubectl get clusterrolebindings.rbac.authorization.k8s.io | grep podsec
            podsecuritypolicy:authenticated                        3m59s

5.  Make kube-proxy metrics accessible to prometheus

    By default kube-proxy metrics are only accessible on localhost. See
    prometheus operator
    [readme](https://github.com/helm/charts/tree/master/stable/prometheus-operator#kubeproxy)

    -   edit configmap
        `kubectl -n kube-system edit cm kube-proxy-config`

    -   set `metricsBindAddress: 0.0.0.0:10249`

    -   delete all `kube-proxy` pods, they will be recreated with the
        new config

    -   if this leads to kube-version-mismatch set the correct image:

            kubectl set image daemonset.apps/kube-proxy \
              -n kube-system \
              kube-proxy=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/kube-proxy:v1.14.9

6. Restore sealed-secret master key from backup