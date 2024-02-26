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

.PHONY: create-namespace
create-namespace:
	kubectl create namespace $(NAMESPACE_NAME) 2>&1 | grep -v "already exists" || true

.PHONY: deploy-service-mesh
deploy-service-mesh:
	sed -i "s#<demo_namespace>#$(NAMESPACE_NAME)#g" config/service-mesh.yaml
	kubectl apply -f config/service-mesh.yaml

.PHONY: deploy-gateway
deploy-gateway:
	kubectl apply -f config/gateway.yaml -n demo

.PHONY: deploy-all
deploy-all: deploy-operators create-namespace build-app build-app2 deploy-service-mesh deploy-app deploy-app2 deploy-gateway

.PHONY: clean
clean:
	kubectl delete namespace $(NAMESPACE_NAME) --ignore-not-found=true
	kubectl delete -f config --ignore-not-found=true
