
Administration Notes
====================

Troubleshooting
---------------

- [Flux source-controller logs](https://dashboard.elifesciences.org/clusters/local/namespaces/flux-system/deployments/source-controller/logs)
- [Flux kustomize-controller logs](https://dashboard.elifesciences.org/clusters/local/namespaces/flux-system/deployments/kustomize-controller/logs)
- [Flux helm-controller logs](https://dashboard.elifesciences.org/clusters/local/namespaces/flux-system/deployments/helm-controller/logs)
- [Flux image-automation-controller logs](https://dashboard.elifesciences.org/clusters/local/namespaces/flux-system/deployments/image-automation-controller/logs)
- [Flux image-reflector-controller logs](https://dashboard.elifesciences.org/clusters/local/namespaces/flux-system/deployments/image-reflector-controller/logs)
- [Flux notification-controller logs](https://dashboard.elifesciences.org/clusters/local/namespaces/flux-system/deployments/notification-controller/logs)
- `helm list`
- `helm history`
- `flux get all -A`
- `flux get images policy` - can help to understand the latest docker tag selected for image automation.

Frequently Used Fixes
---------------------

- `flux reconcile source git flux-system` to synchronise git changes without waiting for source-controller to notice
- `helm rollback` (if helm release is in `failed` state)

## Debugging Helm Chart with HelmRelease values
If `helm lint` is happy but operator is complaining:

-   copy `values` section from the `HelmRelease` to a `dummy.yaml`
-   run `helm dependency update charts/libero-reviewer`
-   now you can run `helm install --dry-run` or `helm template --debug`

## Useful kubectl tools

- [Sniffing Packets](https://github.com/eldadru/ksniff)  dump directly into wireshark or a local file
- [RBAC Overview](https://github.com/jasonrichardsmith/rbac-view)  filterable table of all permissions and who uses them
