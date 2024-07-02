# Adding a new application team

Application teams are empowered to deploy, run, and maintain their own software on top of the platform, in a self-service fashion. The efforts that follow allow to:

- isolate different teams
- make them more autonomous
- lower their cognitive load

## Checklist

1. Decide on a reserved Kubernetes namespace e.g. `sciety`.
1. Create a [Github repository](https://github.com/sciety/deployment) that will contain definitions for all Kubernetes resources. Optionally [create a deploy key](https://fluxcd.io/flux/cmd/flux_create_secret_git/) and add to this repository in github.
1. Sync this repository by adding [a Kustomization for the team](/teams/sciety/), and [a Flux Kustomization](/clusters/flux-prod/sciety-team.yaml).
1. In the kustomizations, create (as needed): 
    1. Create a [dedicated node pool](/teams/sciety/nodepool.yaml) that will host all workloads in a certain namespace.
    1. Create a [dedicated storage class](/teams/sciety/storageclass.yaml) that will configure and tag storage for a namespace.
    1. Create a deployment [sync object](/teams/sciety/deployment-sync.yaml) for the git repository created above, referencing the deploy key secret if created above
1. Test the setup via the creation of the desired [Kubernetes namespace](https://github.com/sciety/deployment/blob/main/manifests/namespace.yaml). **Note:** Make sure to set the annotation to assign workloads to the correct nodepool:
    ```
    apiVersion: v1
    kind: Namespace
    metadata:
    name: application-team-1
    annotations:
        elifesciences.org/default-project: application-team-1
    ```
