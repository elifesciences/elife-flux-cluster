# Uprade EKS and worker nodes

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
kubectl drain my-node   # existing Pods will be evicted and sent to another node
aws ec2 terminate-instances --instance-ids=...  # terminate a node, a new one will be created
```

Copied from [builder docs](https://github.com/elifesciences/builder/blob/master/docs/eks.md#ami-update).


## k8s version upgrade

1. check [aws docs]( https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html ) for availability and notes
1. use [pluto](https://github.com/FairwindsOps/pluto) to check for api deprecations
1. bump k8s version (one minor at a time) in [elife.yaml](https://github.com/elifesciences/builder/blob/master/projects/elife.yaml)
1. apply using `builder/bldr`
1. If `flux` fails to access the api, try restarting it with `kubectl -n flux rollout restart deployment flux`
1. upgrade `kube-proxy` (see [aws docs](https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html))
1. drain and terminate node by node as described above to upgrade the workers

Changing api versions in the chart can lead to helm complaining about `existing resource conflict`.  
  This appears to be an issue with helm3 that helm-operator [is aware of](https://github.com/fluxcd/helm-operator/issues/249) but can't fix until helm3 fixes it upstream.  
  To fix: delete the resource e.g. Deployment, DaemonSet, StatefulSet with `kubectl`. They should automatically be replaced by the new version. This will cause brief downtime.


## Further documentation

https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html
https://github.com/elifesciences/builder/blob/master/docs/eks.md#ami-update
