
SSL with LetsEncrypt
====================

Cluster uses [cert-manager](https://cert-manager.io/) to provide access to letsencrypt certificates.

Usage
-----

Add a TLS section and `cert-manager` annotation  to your `Ingress`:


```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  name: sciencebeam-texture--prod
  namespace: sciencebeam
spec:
  rules:
  - host: sciencebeam.org
    http:
      paths:
      - backend:
          serviceName: sciencebeam-texture--prod
          servicePort: 80
        path: /
  tls:
  - hosts:
    - sciencebeam.org
    secretName: sciencebeam-letsencrypt-cert
```

If using a helm chart, you can probably set this via values in the `HelmRelease` resource:

```yaml
values:
    image:
        repository: elifesciences/sciencebeam_texture
        tag: 0.0.10
    ingress:
        enabled: "true"
        annotations:
        cert-manager.io/cluster-issuer: "letsencrypt"
        hosts:
        - host: sciencebeam-texture.elifesciences.org
        paths:
        - "/"
        - host: sciencebeam.org
        paths:
        - "/"
        tls:
        - secretName: sciencebeam-letsencrypt-cert
        hosts:
        - sciencebeam.org
```

`cert-manager` will obtain a cert for the specified hostname and store it in a secret.
You don't have to do anyting to or with this secret.

NOTE: `letsencrypt-staging` is also available as an issuer if you are doing a lot of certificate generation (letsencrypt prod will throttle at some point).


Observability
---------------

- [list of certificates](https://k8s-dashboard.flux-prod.elifesciences.org/clusters/local/namespaces/_all/certificates?)
- [cert-manager logs](https://k8s-dashboard.flux-prod.elifesciences.org/clusters/local/namespaces/infra/deployments/infra-cert-manager/logs)
- [cert-manager issuers status](https://k8s-dashboard.flux-prod.elifesciences.org/clusters/local/clusterissuers)
