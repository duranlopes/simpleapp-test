# simpleapp-test

[![Terraform CI](https://github.com/duranlopes/simpleapp-test/actions/workflows/terraform-ci.yaml/badge.svg)](https://github.com/duranlopes/simpleapp-test/actions/workflows/terraform-ci.yaml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A hands-on DevOps and Kubernetes laboratory built around a small Flask application. The repository covers application packaging, Kubernetes manifests, Helm-based observability, AWS EKS infrastructure, and local AWS-compatible validation with [Floci](https://github.com/floci-io/floci).

> This repository is a learning and experimentation environment. The legacy Kubernetes manifests and deployment scripts are intentionally preserved, while the Terraform and CI paths are being modernized incrementally.

## What is included

- **Flask application** with health, configuration, and APM endpoints.
- **Docker Compose** definition for running the application locally.
- **Kubernetes manifests** for the application, service, namespace, ConfigMap, HPA, and ingress.
- **Kind cluster bootstrap** for a local multi-node Kubernetes cluster.
- **Helm values** for Elasticsearch and Kibana.
- **k6 load test** container and script.
- **EKS Terraform** using the official VPC and EKS community modules.
- **Floci EKS compatibility test** that creates and destroys a complete mock EKS environment without AWS credentials.
- **GitHub Actions** for Terraform validation and manual AWS deployment.

## Repository layout

```text
.
├── app/                         # Flask application, image, tests, and Compose file
├── assets/                      # Screenshots used by the documentation
├── k6-stresstest/               # k6 load-test image and script
├── kind-cluster/                # Kind cluster configuration and bootstrap script
├── kubernetes/
│   ├── manifests/               # Application Kubernetes resources
│   └── helm/elk/                # Elasticsearch and Kibana values
├── list_ec2_api/               # Small Flask API that lists EC2 instances
├── terraform/
│   ├── modules.tf               # AWS VPC and EKS module composition
│   ├── variables.tf             # AWS deployment inputs and Floci test inputs
│   ├── outputs.tf               # Cluster and network outputs
│   ├── floci.tfvars.example     # Test-only values for the same Terraform root
│   └── docker-compose.floci.yml # Local Floci service
└── .github/workflows/
    ├── terraform-ci.yaml        # Format, validate, apply/destroy against Floci
    └── deploy_terraform.yaml    # Manual AWS plan/apply workflow
```

## Application

The Flask application listens on port `8008` and exposes:

| Endpoint | Purpose |
| --- | --- |
| `/` | Returns the application message |
| `/health` | Readiness/liveness response |
| `/code` | Returns the `Code` environment variable, when configured |

Run it locally with Python:

```bash
cd app
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

Then open `http://127.0.0.1:8008/health`.

Run the published image with Docker Compose:

```bash
docker compose -f app/docker-compose.yaml up -d
curl http://127.0.0.1:8008/health
docker compose -f app/docker-compose.yaml down
```

Build the image locally:

```bash
docker build -t simpleapp-test:local app/
```

The existing Kubernetes deployment references `duran750/simpleapptest:v1`. Publish a compatible image or update `kubernetes/manifests/simpleapp.yaml` before deploying it.

## Local Kubernetes with Kind

Prerequisites:

- Docker
- `kubectl`
- Kind

The bootstrap script installs an older pinned Kind binary when Kind is not already present, creates a three-worker cluster, installs ingress-nginx, waits for the ingress controller, and applies metrics-server:

```bash
cd kind-cluster
./install.sh
kubectl cluster-info --context kind-kind
kubectl get nodes
```

The script uses host ports `80` and `443`. Make sure they are available before running it.

Deploy the application resources:

```bash
kubectl apply -f kubernetes/manifests/ns.yaml
kubectl apply -f kubernetes/manifests/simpleapp-cm.yaml
kubectl apply -f kubernetes/manifests/simpleapp.yaml
kubectl apply -f kubernetes/manifests/simpleapp-svc.yaml
kubectl apply -f kubernetes/manifests/challenge-ingress.yaml
```

The current ingress manifest contains the legacy `extensions/v1beta1` API. Check cluster compatibility before applying it to a current Kubernetes release; migrate it to `networking.k8s.io/v1` when modernizing the workload path.

## Terraform and AWS EKS

The AWS root uses:

- Terraform `>= 1.9.0, < 2.0.0`;
- HashiCorp AWS provider `~> 6.0`;
- `terraform-aws-modules/vpc/aws` `~> 6.0`;
- `terraform-aws-modules/eks/aws` `~> 21.0`;
- a committed `terraform/.terraform.lock.hcl`.

The single Terraform root creates a VPC with public/private subnets, a NAT gateway, an EKS control plane, and an EKS managed node group. Review the Terraform plan and configure a remote backend before using it for shared or long-lived infrastructure.

Initialize and validate the root:

```bash
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform validate
terraform -chdir=terraform plan
```

The real AWS deployment is manual:

```bash
terraform -chdir=terraform init
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

Do not commit credentials, `*.tfvars`, state files, or a local backend configuration containing secrets.

After a successful AWS deployment, configure kubectl with:

```bash
aws eks update-kubeconfig --region us-east-1 --name k8s-cluster
kubectl get nodes
```

## Validate the same Terraform root with Floci

Floci provides a local AWS-compatible endpoint. The CI test points the **same `terraform/` root** at Floci; there is no duplicate Terraform root or Floci-only network module. Only the endpoint, test credentials, and test variable file change.

Start Floci:

```bash
docker compose -f terraform/docker-compose.floci.yml up -d --wait
```

Run the canonical root against Floci:

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://127.0.0.1:4566

terraform -chdir=terraform init -backend=false
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform validate
terraform -chdir=terraform plan -var-file=floci.tfvars.example
terraform -chdir=terraform apply -auto-approve -var-file=floci.tfvars.example
aws eks describe-cluster --name simpleapp-floci
aws eks describe-nodegroup \\
  --cluster-name simpleapp-floci \\
  --nodegroup-name simpleapp-floci-node-group
terraform -chdir=terraform destroy -auto-approve -var-file=floci.tfvars.example
```

The test uses the same official VPC and EKS modules as the AWS deployment. The managed node group is configured to let EKS select its default AMI instead of querying the AWS SSM AMI parameter; this keeps the module graph compatible with Floci while remaining valid for AWS EKS.

Floci validates Terraform resource creation, module wiring, state refresh, EKS API responses, and cleanup. It does **not** validate kubelet behavior, node bootstrapping, CNI networking, Helm workloads, or production AWS networking. Use Kind or a real AWS EKS environment for those checks.

## CI/CD

### Pull requests and pushes

`terraform-ci.yaml` runs:

1. Terraform formatting and validation for the AWS root.
2. Floci startup and health verification.
3. Floci Terraform plan, apply, output assertions, and destroy.
4. Floci cleanup even when a previous step fails.

### Manual AWS deployment

`deploy_terraform.yaml` is triggered with `workflow_dispatch`. It runs Terraform init, format, validate, plan, apply, and show against AWS using:

- `AWS_ACCESS_KEY_ID` repository secret;
- `AWS_SECRET_ACCESS_KEY` repository secret.

Use least-privilege credentials and a remote state backend before enabling this workflow for a shared AWS account.

## Observability and load testing

The repository contains Helm values under `kubernetes/helm/elk/` for Elasticsearch and Kibana. The original README also references Prometheus/Grafana, Metricbeat, and APM Server deployments. Review chart versions and Kubernetes API compatibility before installing them in a new cluster.

The k6 test assets are under `k6-stresstest/`:

```bash
cd k6-stresstest
# Review script.js and the image configuration before running a load test.
```

Run load tests only against an environment intended for that traffic.

## Development conventions

- Keep Terraform modules and providers version-pinned or constrained.
- Run `terraform fmt -check -recursive` and `terraform validate` before committing Terraform changes.
- Use the Floci apply/destroy cycle for EKS API-compatible changes.
- Keep AWS apply manual and never place real credentials in the repository.
- Prefer small conventional commits in English.
- See [`AGENTS.md`](AGENTS.md) for contributor and coding-agent instructions.

## License

This project is released under the MIT License. See [`LICENSE`](LICENSE) when present in the repository.
