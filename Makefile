NAMESPACE_NAME ?= demo
APP_IMG ?= ttl.sh/iblancasa/demo-app1
APP2_IMG ?= ttl.sh/iblancasa/demo-app2


.PHONY: build-app
build-app:
	docker build -t $(APP_IMG) app
	docker push $(APP_IMG)

.PHONY: deploy-app
deploy-app:
	sed -i "s#<image_name>#$(APP_IMG)#g" app/manifest.yaml
	kubectl apply -f app/manifest.yaml -n $(NAMESPACE_NAME)

.PHONY: build-app2
build-app2:
	docker build -t $(APP2_IMG) app2
	docker push $(APP2_IMG)

.PHONY: deploy-app2
deploy-app2:
	sed -i "s#<image_name2>#$(APP2_IMG)#g" app2/manifest.yaml
	kubectl apply -f app2/manifest.yaml -n $(NAMESPACE_NAME)
 
.PHONY: deploy-operators
deploy-operators:
	kubectl apply -f config/operators.yaml
	sleep 10
	kubectl wait --for=condition=available deployment istio-operator -n openshift-operators --timeout=5m
	kubectl wait --for=condition=available deployment kiali-operator -n openshift-operators --timeout=5m
	kubectl wait --for=condition=available deployment tempo-operator-controller -n openshift-tempo-operator --timeout=5m

.PHONY: create-namespace
create-namespace:
	kubectl create namespace $(NAMESPACE_NAME) 2>&1 | grep -v "already exists" || true

.PHONY: deploy-tempo
deploy-tempo:
	kubectl apply -f config/tempo.yaml
	sleep 10
	kubectl wait --for=condition=available deployment tempo-sample-compactor -n tracing-system --timeout=5m
	kubectl wait --for=condition=available deployment tempo-sample-distributor -n tracing-system --timeout=5m
	kubectl wait --for=condition=available deployment tempo-sample-querier -n tracing-system --timeout=5m
	kubectl wait --for=condition=available deployment tempo-sample-query-frontend -n tracing-system --timeout=5m

.PHONY: patch-kiali
patch-kiali:
	kubectl patch  kiali kiali -p '[{"op": "replace", "path": "/spec/external_services/tracing", "value": {query_timeout: 30, enabled: true, in_cluster_url: "http://tempo-sample-query-frontend.tracing-system.svc.cluster.local:16686", url: "localhost:16686"}}]' --type=json -n istio-system

.PHONY: deploy-service-mesh
deploy-service-mesh:
	sed -i "s#<demo_namespace>#$(NAMESPACE_NAME)#g" config/service-mesh.yaml
	kubectl apply -f config/service-mesh.yaml
	sleep 60

.PHONY: deploy-gateway
deploy-gateway:
	kubectl apply -f config/gateway.yaml -n demo

.PHONY: deploy-all
deploy-all: deploy-operators create-namespace build-app build-app2 deploy-service-mesh deploy-gateway deploy-tempo deploy-app deploy-app2 patch-kiali

.PHONY: clean
clean:
	kubectl delete namespace $(NAMESPACE_NAME) --ignore-not-found=true
	kubectl delete -f config --ignore-not-found=true
