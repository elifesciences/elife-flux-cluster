# This script attempts to update all crds based on the version described in deployed manifests

cd $(dirname $0)

./cert-manager/update.sh $(cat ../system/infra/cert-manager/release.yaml | yq .spec.chart.spec.version)
./external-secrets/update.sh v$(cat ../system/external-secrets/external-secrets/release.yaml | yq .spec.chart.spec.version)
./karpenter/update.sh v$(cat ../nodes/karpenter/release.yaml | yq .spec.chart.spec.version)
./keda/update.sh $(cat ../system/keda/release.yaml | yq .spec.chart.spec.version)
./keda-http-add-on/update.sh $(cat ../system/keda/release-http-addon.yaml  | yq .spec.chart.spec.version)
./kong-operator/update.sh $(cat ../system/kong-system/release.yaml  | yq .spec.chart.spec.version)
./pg-operator/update.sh $(cat ../system/database/postgresql/pg-operator-release.yaml | yq .spec.chart.spec.version)
./psmdb-operator/update.sh $(cat ../system/database/mongodb/psmdb-operator-release.yaml | yq .spec.chart.spec.version)
./pxc-operator/update.sh $(cat ../system/database/mysql/pxc-operator-release.yaml  | yq .spec.chart.spec.version)
./sealed-secrets/update.sh $(cat ../system/infra/sealed-secrets/release.yaml  | yq .spec.chart.spec.version)
./template-controller/update.sh $(cat ../system/template-controller/release.yaml  | yq .spec.chart.spec.version)
./victoriametrics/update.sh $(cat ../system/victoriametrics/release.yaml  | yq .spec.chart.spec.version)

./ack-controllers/documentdb-controller/update.sh $(cat ../system/ack-system/documentdb-release.yaml  | yq .spec.chart.spec.version)
./ack-controllers/elasticache-controller/update.sh $(cat ../system/ack-system/elasticache-release.yaml  | yq .spec.chart.spec.version)
