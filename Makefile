NAMESPACE_NAME ?= demo
APP_IMG ?= ttl.sh/iblancasa/demo-app1


.PHONY: build-app
build-app:
	docker build -t $(APP_IMG) app
	docker push $(APP_IMG)

.PHONY: deploy-app
deploy-app:
	sed -i "s#<image_name>#$(APP_IMG)#g" app/manifest.yaml
	kubectl apply -f app/manifest.yaml -n $(NAMESPACE_NAME)
 
.PHONY: deploy-operators
deploy-operators:
	kubectl apply -f config/operators.yaml

.PHONY: create-namespace
create-namespace:
	kubectl create namespace $(NAMESPACE_NAME) 2>&1 | grep -v "already exists" || true

.PHONY: deploy-service-mesh
deploy-service-mesh:
	sed -i "s#<demo_namespace>#$(NAMESPACE_NAME)#g" config/service-mesh.yaml
	kubectl apply -f config/service-mesh.yaml

.PHONY: deploy-gateway
deploy-gateway:
	kubectl apply -f config/gateway.yaml

.PHONY: deploy-all
deploy-all: deploy-operators create-namespace build-app deploy-service-mesh deploy-app deploy-gateway

.PHONY: clean
clean:
	kubectl delete namespace $(NAMESPACE_NAME) --ignore-not-found=true
	kubectl delete -f config --ignore-not-found=true
