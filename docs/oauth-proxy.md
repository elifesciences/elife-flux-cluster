
Authentication Proxy
====================

[oauth2 proxy](https://oauth2-proxy.github.io/oauth2-proxy/) available to protect services without their own login.

Provides access to all members of elifesciences Github organisation.

Add following annotations to your service’s ingress:

    annotations:
      traefik.ingress.kubernetes.io/router.middlewares: traefik-elife-oauth@kubernetescrd
