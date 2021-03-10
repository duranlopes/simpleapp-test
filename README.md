# simpleapp-test

## Build Python Docker image:

```
cd /app

docker build -t duran750/simpleapptest:latest

docker push duran750/simpleapptest:latest
```

## Kubernetes Manifests 

```
cd /kubernetes/manifests

#Namespace: 
kubectl create-f ns.yaml

#ConfigMap:
kubectl create-f simpleapp-cm.yaml

#Deployment: 
kubectl create-f simpleapp.yaml

#Service
kubectl create -f simpleapp-svc.yaml

#Ingress Controller
kubectl create -f challenge-ingress-yaml

#Default output 
➜ kubectl get all -n prova               

```

## Helm 

### Prometheus Stack

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack
```

*obs: Default grafana password is `prom-operator`