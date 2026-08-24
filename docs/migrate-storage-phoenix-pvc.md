# Description

Migrate the `data-ai-bot` team's `phoenix--prod` PVC to a specific AZ (e.g. `us-east-1c`).

Unlike the MongoDB case (`migrate-storage-mongodb-cluster.md`), `phoenix--prod` is a
single-replica StatefulSet (Arize Phoenix, `manifests/deployments/data-ai-bot/phoenix--prod.yaml`
in `data-hub-team-deployment`) with no application-level replication, so there is no second
copy of the data to resync from. The volume must be moved via an EBS/CSI snapshot instead of
a delete-and-resync.

Resources involved:
- Namespace: `data-ai-bot`
- StatefulSet: `phoenix--prod`
- PVC: `phoenix-phoenix--prod-0` (from volumeClaimTemplate `phoenix`)
- StorageClass: `data-hub-gp3` (`ebs.csi.aws.com`, `WaitForFirstConsumer`, `reclaimPolicy: Delete`)
- VolumeSnapshotClass: `data-hub-csi-ebs` (`ebs.csi.aws.com`)

# Check before starting

Confirm the PVC isn't already in the target zone:
```
kubectl get pv $(kubectl -n data-ai-bot get pvc phoenix-phoenix--prod-0 -o jsonpath='{.spec.volumeName}') -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
```

Confirm a `data-hub`-discoverable subnet exists in the target zone (Karpenter needs somewhere to
place the node) and check data size to gauge the outage window:
```
kubectl exec -n data-ai-bot phoenix--prod-0 -- du -sh /mnt/data
```

This is a short planned outage: Phoenix has one replica, so it's unavailable while its pod is down.

`phoenix--prod` is reconciled by the `data-hub-team-deployment` Flux Kustomization
(`teams/data-hub/deployment-sync.yaml` in this repo), which polls every 10 minutes with
`prune: true`. Every step below that touches live cluster state without a matching git change
(scaling to 0, deleting/recreating the PVC) must happen with that Kustomization **suspended** —
otherwise Flux will scale the StatefulSet back to 1 mid-migration, racing the PVC swap. Do not
merge the nodeAffinity PR (step 5) until the old PVC/AZ has already been swapped out — merging it
while the pod is still bound to a PV in the old AZ makes the pod unschedulable (EBS volumes can't
attach across AZs).

# Steps

1. Set the current PV to `Retain` so a later PVC delete can never destroy the EBS volume:
   ```
   kubectl patch pv <the-pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
   ```
   Verify with `kubectl get pv`.

2. Suspend Flux reconciliation for this app for the duration of the migration:
   ```
   flux suspend kustomization data-hub-team-deployment -n flux-system
   ```

3. Scale the StatefulSet to 0 to stop writes, for a clean/consistent snapshot:
   ```
   kubectl -n data-ai-bot scale statefulset phoenix--prod --replicas=0
   ```

4. Take a VolumeSnapshot of the PVC:
   ```yaml
   apiVersion: snapshot.storage.k8s.io/v1
   kind: VolumeSnapshot
   metadata:
     name: phoenix-phoenix--prod-0-migration
     namespace: data-ai-bot
   spec:
     volumeSnapshotClassName: data-hub-csi-ebs
     source:
       persistentVolumeClaimName: phoenix-phoenix--prod-0
   ```
   Wait for it to become ready: `kubectl -n data-ai-bot get volumesnapshot phoenix-phoenix--prod-0-migration -o jsonpath='{.status.readyToUse}'`

5. Delete the old PVC (safe: the PV is retained and the snapshot exists):
   ```
   kubectl -n data-ai-bot delete pvc phoenix-phoenix--prod-0
   ```

6. Recreate a PVC with the same name, restored from the snapshot:
   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: phoenix-phoenix--prod-0
     namespace: data-ai-bot
   spec:
     accessModes:
     - ReadWriteOnce
     storageClassName: data-hub-gp3
     resources:
       requests:
         storage: 1Gi
     dataSource:
       name: phoenix-phoenix--prod-0-migration
       kind: VolumeSnapshot
       apiGroup: snapshot.storage.k8s.io
   ```
   Because the StorageClass is `WaitForFirstConsumer`, this stays `Pending` until a pod claims it.

7. Now pin the pod to the target zone. Open a PR against `manifests/deployments/data-ai-bot/phoenix--prod.yaml`
   (`data-hub-team-deployment` repo) adding to the StatefulSet's pod template spec (same pattern as
   `system/clusters/flux-prod/patches/psmdb-on-controlplane-az.yaml` in this repo):
   ```yaml
   affinity:
     nodeAffinity:
       requiredDuringSchedulingIgnoredDuringExecution:
         nodeSelectorTerms:
         - matchExpressions:
           - key: topology.kubernetes.io/zone
             operator: In
             values:
             - us-east-1c
   ```
   Merge the PR, then apply the same change live immediately with `kubectl patch statefulset
   phoenix--prod -n data-ai-bot ...` (or `kubectl apply` against the patched manifest) — do this
   manually rather than waiting for Flux, since the Kustomization is still suspended. Applying it
   live in step with the git merge means there's no drift for Flux to fight over once resumed.

8. Scale the StatefulSet back up:
   ```
   kubectl -n data-ai-bot scale statefulset phoenix--prod --replicas=1
   ```
   Karpenter provisions a node in the target zone (per step 7), the PVC binds, and the EBS CSI
   driver creates a new gp3 volume there, restored from the snapshot.

9. Resume Flux reconciliation now that live state matches git (nodeAffinity present, replicas: 1
   in both):
   ```
   flux resume kustomization data-hub-team-deployment -n flux-system
   ```
   Reconciliation should be a no-op — if `flux get kustomization data-hub-team-deployment -n
   flux-system` shows drift, investigate before moving on.

# Verify

- Pod is `Running`, ingress reachable, `/mnt/data` contents/size match the pre-migration check.
- New PV is in the target zone:
  ```
  kubectl get pv $(kubectl -n data-ai-bot get pvc phoenix-phoenix--prod-0 -o jsonpath='{.spec.volumeName}') -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
  ```
- Let it burn in for 24-48h before cleanup.

# Cleanup (after burn-in)

- Delete the old (retained) PV/EBS volume and the migration VolumeSnapshot.
- Keep the `nodeAffinity` zone pin in place permanently — it's what stops a future Karpenter
  reschedule from drifting to a different AZ and forcing this process to be repeated.

# Rollback

At any point before step 5 (deleting the old PVC), the original EBS volume is untouched and still
`Retain`ed, and the snapshot is an independent copy. Either can be used to restore the old pod in
its original AZ if something goes wrong.
