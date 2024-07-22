KubeVersion = 1.27
NextKubeVersion = 1.28
RenderChart = echo "> Rendering $(1)..." && yq '.spec.values' $(1) | helm template --kube-version=$(KubeVersion)  -f - $(shell yq '.metadata.name' $(1)) --repo $(shell yq '.spec.chart.repository' $(1)) $(shell yq '.spec.chart.name' $(1)) > /dev/null && echo ">> OK"
DryRunApply = echo "> Dry-run applying $(1)..." && kubectl apply -f $(1) --validate=true --dry-run=client > /dev/null && echo ">> OK"
DryRunApplyChart = echo "> Dry-run applying $(1)..." && yq '.spec.values' $(1) | helm template --kube-version=$(KubeVersion)  -f - $(shell yq '.metadata.name' $(1)) --repo $(shell yq '.spec.chart.repository' $(1)) $(shell yq '.spec.chart.name' $(1)) | kubectl apply -f - --validate=true --dry-run=client  > /dev/null && echo ">> OK"


# targets operating on local files
validate:
	scripts/validate.sh

test: validate


# targets for interacting with flux in the cluster
reconcile:
	flux reconcile kustomization flux-system --with-source
	flux reconcile kustomization policies
	flux reconcile kustomization nodes
	flux reconcile kustomization crds
	flux reconcile kustomization system
	flux reconcile kustomization deployments

# targets to show logs for main cluster components
logs-flux:
	kubectl logs -f -n flux deployment/flux

logs-nginx:
	kubectl logs -f -n infra deployment/infra-ingress-nginx-controller

logs-certmanager:
	kubectl logs -f -n infra deployment/infra-cert-manager

logs-external-dns:
	kubectl logs -f -n infra deployment/infra-external-dns

logs-oauth2-proxy:
	kubectl logs -f -n infra deployment/infra-oauth2-proxy

logs-sealed-secrets:
	kubectl logs -f -n infra deployment/infra-sealed-secrets

logs-autoscaler:
	kubectl logs -f -n autoscaler deployment/cluster-autoscaler-aws-cluster-autoscaler


# target to help with debugging
watch-helm-releases:
	watch helm list -A


# targets that help during an upgrade
detect-needed-api-upgrades:
	pluto detect-helm -o wide --ignore-deprecations -r || true
	kubedd --target-kubernetes-version=$(NextKubeVersion) --source-kubernetes-version=$(KubeVersion) -d clusters,deployments,kustomizations,system || true
	kubedd --target-kubernetes-version=$(NextKubeVersion)  || true

watch-nodes:
	watch -w -n0.5 'kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type,CREATED:.metadata.creationTimestamp,PROVIDERID:.spec.providerID,PROJECT:.metadata.labels.elifesciences\\.org/project,NODEPOOL:.metadata.labels.karpenter\\.sh/nodepool,CAPACITYTYPE:.metadata.labels.karpenter\\.sh/capacity-type,INSTANCETYPE:.metadata.labels.beta\\.kubernetes\\.io/instance-type,ZONE:.metadata.labels.topology\\.kubernetes\\.io/zone | sort -k6b,6'

watch-nodes-upgrading:
	watch -t "kubectl get nodes --sort-by=.metadata.name -o custom-columns=NAME:.metadata.name,INSTANCE:.spec.providerID,VERSION:.status.nodeInfo.kubeletVersion,READY?:.status.conditions[3].status"

watch-pods-upgrading:
	watch "kubectl get pods -A --sort-by=.spec.nodeName -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY?:.status.conditions[*].status,NODE:.spec.nodeName,IMAGE:.status.containerStatuses[*].image"

watch-pods-nodes-upgrading:
	watch "kubectl get pods -A --sort-by=.spec.nodeName -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY?:.status.conditions[*].status,NODE:.spec.nodeName"

epp-prod-server-port-forward:
	kubectl port-forward -n epp--prod deployment/epp-server 3000:3000

epp-staging-server-port-forward:
	kubectl port-forward -n epp--staging deployment/epp-server 3000:3000

epp-staging-mongo-0:
	kubectl exec -n epp--staging  mongodb-psmdb-db-rs0-0 -it -- bash -c 'mongosh --authenticationDatabase admin --username $$MONGODB_DATABASE_ADMIN_USER  --password $$MONGODB_DATABASE_ADMIN_PASSWORD'

epp-staging-mongo-1:
	kubectl exec -n epp--staging  mongodb-psmdb-db-rs0-1 -it -- bash -c 'mongosh --authenticationDatabase admin --username $$MONGODB_DATABASE_ADMIN_USER  --password $$MONGODB_DATABASE_ADMIN_PASSWORD'

epp-staging-mongo-2:
	kubectl exec -n epp--staging  mongodb-psmdb-db-rs0-2 -it -- bash -c 'mongosh --authenticationDatabase admin --username $$MONGODB_DATABASE_ADMIN_USER  --password $$MONGODB_DATABASE_ADMIN_PASSWORD'

epp-prod-mongo-0:
	kubectl exec -n epp--prod  mongodb-psmdb-db-rs0-0 -it -- bash -c 'mongosh --authenticationDatabase admin --username $$MONGODB_DATABASE_ADMIN_USER  --password $$MONGODB_DATABASE_ADMIN_PASSWORD'

epp-prod-mongo-1:
	kubectl exec -n epp--prod  mongodb-psmdb-db-rs0-1 -it -- bash -c 'mongosh --authenticationDatabase admin --username $$MONGODB_DATABASE_ADMIN_USER  --password $$MONGODB_DATABASE_ADMIN_PASSWORD'

epp-prod-mongo-2:
	kubectl exec -n epp--prod  mongodb-psmdb-db-rs0-2 -it -- bash -c 'mongosh --authenticationDatabase admin --username $$MONGODB_DATABASE_ADMIN_USER  --password $$MONGODB_DATABASE_ADMIN_PASSWORD'
