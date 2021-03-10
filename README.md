# simpleapp-test

## Build Python Docker image:

```
cd app/

docker build -t duran750/simpleapptest:latest

docker push duran750/simpleapptest:latest
```

## Kubernetes Manifests 

```
cd kubernetes/manifests

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

## Python

### List EC2 Instances - To run this script it is necessary to install the Boto3 library and configure aws cli

```
# Configure aws access key and secret key
aws configure

cd list_ec2/
pip install -r requirements.txt

python3 get_ec2.py
```