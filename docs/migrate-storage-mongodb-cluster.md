# Description

An easy way to migrate a MongoDB cluster that has a replicaset size > 1 is to rely on the replication of data to brand new volumes.

# Monitor replicaset status:
```
kubectl exec -n epp--migration-test sts/epp-database-psmdb-db-replicaset -it -- bash -c 'mongosh -u "$MONGODB_CLUSTER_ADMIN_USER" -p "$MONGODB_CLUSTER_ADMIN_PASSWORD" --authenticationDatabase admin --eval "rs.status()"'
```
# Steps

1. Set all affected persistentvolumes to retain: `kubectl patch pv <the-pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'`. Verify with `kubectl get pv`
2. Change the STS volume template
   1. volume templates are not patchable, so changing the desired config (either a manifest or through the operator)
   2. Then remove the statefulset retaining all the pods using `kubectl delete -n <the-namespace> sts <sts-name> --cascade=orphan`
   3. If using the mongodb-operator, it seems it needs a bit of a kick too, delete the cluster object: `kubectl delete -n <the-namespace> perconaservermongodbs.psmdb.percona.com <cluster-name>`
   4. Allow flux or the operator to recreate the STS. This may trigger a replacement of all members. Wait for this to complete before proceeding.
3. For each replica:
   1. Delete the pvc `kubectl delete -n <the-namespace> pvc <volume-template-name>-0`
   2. Delete the pod `kubectl delete -n <the-namespace> pod <sts-name>-0`
   3. Wait for the new pod to arrive and to catch up to replication
