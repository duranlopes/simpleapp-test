# simpleapp-test


## Deploy IaC

### - Terraform 

```
## Initiate provider
terraform init

## Apply the modules
terraform apply

```

### Change Kubernetes context

```
aws eks --region us-east-1 update-kubeconfig --name k8s-demo
```

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
kubectl create -f ns.yaml

#ConfigMap:
kubectl create -f simpleapp-cm.yaml

#Deployment: 
kubectl create -f simpleapp.yaml

#Service
kubectl create -f simpleapp-svc.yaml


#Ingress Controller
kubectl create -f challenge-ingress-yaml
          

```

### K8s Features
```
# Deploy Nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/aws/deploy.yaml


# Deploy metric server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```



## Helm 

### Install

```
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
```

### Prometheus Stack

```
# Deploy Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && \
helm repo update && \
helm install prometheus prometheus-community/kube-prometheus-stack 
```

### ELK Stack

```
helm repo add elastic https://Helm.elastic.co && \
helm repo update && \
helm install elasticsearch elastic/elasticsearch -n prova && \
helm install kibana elastic/kibana -n prova && \
helm install metricbeat elastic/metricbeat -n prova
```



## Python

### List EC2 Instances - To run this script it is necessary to install the Boto3 library and configure aws cli

```
# Configure aws access key and secret key
aws configure

cd list_ec2/

pip install -r requirements.txt

python3 get_ec2.py

```


## Samples

### Grafana dashboard

*obs: Default grafana user: `admin` and password is `prom-operator`

![Grafana dashboard](assets/grafana_namespace_pods.png)


### Kibana

![Kibana metric dashboard](assets/kibana_metrics_pods.png)