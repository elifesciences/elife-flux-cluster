# Adding a new application team

Application teams are empowered to deploy, run, and maintain their own software on top of the platform, in a self-service fashion. The efforts that follow allow to:

- isolate different teams
- make them more autonomous
- lower their cognitive load

## Checklist

1. Decide on a reserved Kubernetes namespace e.g. `sciety`.
1. Create a [Github repository](https://github.com/sciety/deployment) that will contain definitions for all Kubernetes resources.
1. Sync this repository by adding [a Kustomization](/clusters/flux-prod/sciety-team/).
1. Create a [dedicated node pool](/nodes/clusters/flux-prod/nodepools) that will host all workloads in a certain namespace.
1. Test the setup via the creation of the desired [Kubernetes namespace](https://github.com/sciety/deployment/blob/main/manifests/namespace.yaml). **Note:** Make sure to set the annotation to assign workloads to the correct nodepool:
    ```
    apiVersion: v1
    kind: Namespace
    metadata:
    name: application-team-1
    annotations:
        elifesciences.org/default-project: application-team-1
    ```
