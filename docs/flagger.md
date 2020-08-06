
Progressive Delivery
====================

The cluster has [Flagger](https://docs.flagger.app/) installed. This can be used for:

- canary style traffic shifting
- blue/green style promotion
- loadtesting canaries/deploys
- conformance testing with e.g. `helm test`
- automated rollbacks based on webhooks and/or prometheus queries

This behaviour is attached to a specific `Deployment` and `Ingress` object through the creation of `Canary` objects.

## Smoke/Conformance Tests

Flagger provides a set of [hooks to gate rollouts](https://docs.flagger.app/usage/webhooks). Hooks can call a URL or execute commands on the `flagger-loadtester` deployments which comes with `helm`, `bats` and `hey`.

The pattern used for [reviewer](https://github.com/elifesciences/elife-flux-test/blob/master/releases/prod/libero-reviewer.yaml) is:

- bundle browsertests into a container
- declare a k8s job as a helm test hook
- parametrise the job with a target url and test suite to run

When flagger detects a change to the `reviewer--prod` deployments:

- spin up canary
- check if `stg` and `prod` images and chart match
- run acceptance browser tests agains `stg`
- start shifting traffic to canary
- smoketest canary with browsertests
- loadtest public facing url
- rollback if anything fails

## Gotchas

- `name` of `Deployment` has to match its `metadata`
  The default `helm` template uses `name` for the former and `fullname` for the latter which buggers up the `ingress` and `service` definitions created by flagger.
- default analysis metrics expect ingress controlller in same namespace as canary
  Since we have a single central controller living in `adm` we need to use a custom metric template. This hardcodes the namespace as the `templateRef.namespace` only locates the `MetricTemplate` object.
- metric `interval` should be at least `1m`
  Shorter durations lead to empty `rate` values being returned by Prometheus as the windows will only have a single data point.
