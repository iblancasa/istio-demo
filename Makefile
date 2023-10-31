
KUBE_VERSION ?= 1.28
KIND_CONFIG ?= kind-$(KUBE_VERSION).yaml
KIND_CLUSTER_NAME ?= istio-demo


CERTMANAGER_VERSION ?= 1.10.0
ISTIO_VERSION ?= "1.17.0"
ISTIO_SHORT_VERSION = "$(shell echo $(ISTIO_VERSION) | grep -oE '[0-9]\.[0-9]+')"

LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

ISTIOCTL ?= $(LOCALBIN)/istioctl
KIND ?= $(LOCALBIN)/kind
CMCTL ?= $(LOCALBIN)/cmctl

# Install istioctl
.PHONY: istioctl
istioctl: $(ISTIOCTL)
$(ISTIOCTL): $(LOCALBIN)
	cd $(LOCALBIN) && curl -sL https://istio.io/downloadIstio | ISTIO_VERSION=$(ISTIO_VERSION) TARGET_ARCH=x86_64 sh -
	mv $(LOCALBIN)/istio-$(ISTIO_VERSION)/bin/istioctl $(LOCALBIN)
	rm -rf $(LOCALBIN)/istio-$(ISTIO_VERSION)

# Install kind
.PHONY: kind
kind: $(KIND)
$(KIND): $(LOCALBIN)
	GOBIN=$(LOCALBIN) go install sigs.k8s.io/kind@v0.17.0

.PHONY: cmctl
cmctl:
	@{ \
	set -e ;\
	if (`pwd`/bin/cmctl version | grep ${CERTMANAGER_VERSION}) > /dev/null 2>&1 ; then \
		exit 0; \
	fi ;\
	TMP_DIR=$$(mktemp -d) ;\
	curl -L -o $$TMP_DIR/cmctl.tar.gz https://github.com/jetstack/cert-manager/releases/download/v$(CERTMANAGER_VERSION)/cmctl-`go env GOOS`-`go env GOARCH`.tar.gz ;\
	tar xzf $$TMP_DIR/cmctl.tar.gz -C $$TMP_DIR ;\
	[ -d bin ] || mkdir bin ;\
	mv $$TMP_DIR/cmctl $(CMCTL) ;\
	rm -rf $$TMP_DIR ;\
	}


# Start kind cluster
.PHONY: start-kind
start-kind: kind
	echo "Starting KIND cluster..."
	$(KIND) create cluster --config config/kind.yaml 2>&1 | grep -v "already exists" || true

	kubectl wait --timeout=5m --for=condition=available deployment/coredns -n kube-system

	# Ingress Controller
	kubectl create -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.1/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/component=controller \
		--timeout=90s

	# Load balancer
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
	kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s
	kubectl apply -f https://kind.sigs.k8s.io/examples/loadbalancer/metallb-config.yaml


.PHONY: install-istio
deploy-istio: istioctl
	$(ISTIOCTL) install --set profile=demo -y --set meshConfig.defaultConfig.tracing.zipkin.address=distributor.tempo.svc.cluster.local:9411


.PHONY: deploy-kiali
deploy-kiali:
	kubectl apply -f config/kiali.yaml


.PHONY: deploy-prometheus
deploy-prometheus:
	kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-$(ISTIO_SHORT_VERSION)/samples/addons/prometheus.yaml

.PHONY: deploy-jaeger-operator
deploy-jaeger-operator:
	kubectl create namespace observability 2>&1 | grep -v "already exists" || true
	kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.49.0/jaeger-operator.yaml

.PHONY: deploy-jaeger
deploy-jaeger:
	kubectl apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-operator/v1.49.0/examples/simplest.yaml

.PHONY: cert-manager
cert-manager: cmctl
	# Consider using cmctl to install the cert-manager once install command is not experimental
	kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v${CERTMANAGER_VERSION}/cert-manager.yaml
	$(CMCTL) check api --wait=5m

.PHONY: deploy-all
deploy-all: start-kind cert-manager deploy-jaeger-operator deploy-istio deploy-prometheus deploy-jaeger deploy-kiali
