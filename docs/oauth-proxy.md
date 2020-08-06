
Authentication Proxy
====================

[oauth2 proxy](https://oauth2-proxy.github.io/oauth2-proxy/) available to protect services without their own login.

Provides access to all members of elifesciences Github organisation.

Add following annotations to your service’s ingress:

    annotations:
      nginx.ingress.kubernetes.io/auth-url: "https://oauth-proxy.elifesciences.org/oauth2/auth"
      nginx.ingress.kubernetes.io/auth-signin: "https://oauth-proxy.elifesciences.org/oauth2/start?rd=https%3A%2F%2F$host$request_uri"
