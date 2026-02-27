# Uprade EKS and worker nodes

NOTE: The clusters now use managed node groups and karpenter for all nodes. Most of the instructions here are no longer relevant, but are kept for posterity.

AWS EKS doesn't update the cluster automatically.

__Subscribe to the Amazon Linux AMI [Security Bulletin](https://alas.aws.amazon.com/alas2.html)__

## Security Patch for Worker AMI

1. Check if new [EKS AMI available](https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html) after ALAS2 alert
1. if needed increase worker count via builder (unless we have autoscaling)
1. Manually drain and kill each node that uses old AMI
1. Check in EC2 console if workers are using new AMI

To manually drain and kill the nodes:
```
kubectl get nodes       #
kubectl cordon my-node  # no new Pods will be scheduled here
kubectl drain --ignore-daemonsets my-node   # existing Pods will be evicted and sent to another node
aws ec2 terminate-instances --instance-ids=...  # terminate a node, a new one will be created
```

`kubectl drain` will complain if pods are using local data storage or if evicting a pod would violate a `PodDisruptionBudget`.
You can force the eviction using `--delete-local-data` and `--disable-eviction` respectively.
Check which pods are complaining before doing this and make sure that this wouldn't break production services.

Copied from [builder docs](https://github.com/elifesciences/builder/blob/master/docs/eks.md#ami-update).


## k8s version upgrade

1. check [aws docs]( https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html ) for availability and notes
1. use [silver-surfer/kubedd](https://github.com/devtron-labs/silver-surfer) to check for api deprecations
   `kubedd --target-kubernetes-version=1.22` (example for 1.22 upgrade)
   `DEPRECATED` is okay, but if an api is `DELETED` in the new k8s version you will have to fix the affected charts.
1. bump k8s version (one minor at a time) in [elife.yaml](https://github.com/elifesciences/builder/blob/master/projects/elife.yaml)
1. apply using `builder/bldr update_infrastructure:kubernetes-aws--flux-prod`
   This should change the EKS (i.e k8s control plane) and AutoscalingGroup AMI image.
1. If `flux` fails to access the api after the EKS upgrade, try restarting it with `kubectl -n flux rollout restart deployment flux`
1. upgrade `kube-proxy` (see [aws docs](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html))
1. drain and terminate node by node as described above to upgrade the workers

Changing api versions in the chart can lead to helm complaining about `existing resource conflict`.
  This appears to be an issue with helm3 that helm-operator [is aware of](https://github.com/fluxcd/helm-operator/issues/249) but can't fix until helm3 fixes it upstream.
  To fix: delete the resource e.g. Deployment, DaemonSet, StatefulSet with `kubectl`. They should automatically be replaced by the new version. This will cause brief downtime.


## Further documentation

https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html
https://github.com/elifesciences/builder/blob/master/docs/eks.md#ami-update
