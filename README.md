# istio-demo

How to curl the app:

```sh
export CONTROL_PLANE_NS=istio-system
export GATEWAY_URL=$(oc -n ${CONTROL_PLANE_NS} get route istio-ingressgateway -o jsonpath='{.spec.host}')
curl $GATEWAY_URL
```