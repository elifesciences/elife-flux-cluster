
Administration Notes
====================

Troubleshooting
---------------

- [Flux logs](https://k9s-dashboard.elifesciences.org/clusters/local/namespaces/flux/deployments/flux/logs)
- [HelmOperator logs](https://k8s-dashboard.elifesciences.org/clusters/local/namespaces/flux/deployments/helm-operator/logs)
- `helm list`
- `helm history`

Frequently Used Fixes
---------------------

- `fluxctl --k8s-fwd-ns flux sync` (don't want to wait five minutes for automated sync)
- `kubectl rollout restart` (have you tried turning it of and on again)
- `helm rollback` (if helm release is in `failed` state)

## Debugging Helm Chart with HelmRelease values
If `helm lint` is happy but operator is complaining:

-   copy `values` section from the `HelmRelease` to a `dummy.yaml`
-   run `helm dependency update charts/libero-reviewer`
-   now you can run `helm install --dry-run` or `helm template --debug`

## Useful kubectl tools

- [Sniffing Packets](https://github.com/eldadru/ksniff)  dump directly into wireshark or a local file
- [RBAC Overview](https://github.com/jasonrichardsmith/rbac-view)  filterable table of all permissions and who uses them
- [Deprecatand and Removed APIs](https://github.com/FairwindsOps/pluto)  use before cluster upgrades
