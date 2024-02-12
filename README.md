# rbac-helm-demo

```shell

# create your namspaces first
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace prod

helm upgrade --install rbac-demo . --namespace rbac --create-namespace
```
