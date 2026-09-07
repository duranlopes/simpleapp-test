# AGENTS.md

Instructions for coding agents and contributors working in `simpleapp-test`.

## Project scope

This repository is a learning-oriented DevOps laboratory. It contains:

- a Flask application under `app/`;
- Docker Compose and Docker image definitions;
- Kubernetes manifests under `kubernetes/manifests/`;
- Kind bootstrap files under `kind-cluster/`;
- observability values for Elasticsearch and Kibana;
- a k6 load-test example;
- an AWS Terraform root under `terraform/`;
- a Floci Docker service used to validate that same Terraform root.

The AWS and Floci runs use the same Terraform module graph. Floci changes only the endpoint, credentials, and test variable file; it must not receive a duplicate Terraform root or duplicate network module.

## Language and style

- Write source code, Terraform, YAML keys, comments, documentation, and commit messages in English.
- Keep user-facing chat communication in concise Brazilian Portuguese when appropriate.
- Use conventional commits in English, for example:
  - `refactor(terraform): update EKS module`
  - `test(terraform): validate EKS against Floci`
  - `docs: refresh project README`
- Prefer small, focused commits. Do not combine unrelated application, Kubernetes, Terraform, and CI changes.

## Repository rules

- Never commit AWS credentials, private keys, local state, plans, or sensitive `.tfvars` files.
- Do not run `terraform apply` against AWS unless the user explicitly requests it and the target account, region, state backend, and destroy plan are understood.
- Keep AWS deployment workflows manual. Pull requests must not apply to AWS.
- Use the Floci environment for local EKS API validation.
- Use Kind or a real EKS environment when validating Kubernetes scheduling, CNI behavior, kubelet behavior, Helm workloads, or ingress behavior.
- Do not silently delete legacy manifests or modules. If they are no longer referenced, document the fact and remove them in a separate, deliberate cleanup change.
- Do not hardcode personal paths, usernames, account IDs, tokens, or machine-specific IP addresses.

## Terraform architecture

### AWS root

The production-oriented root is `terraform/`:

- `terraform/modules.tf` composes the official VPC and EKS modules.
- `terraform/variables.tf` defines deployment inputs.
- `terraform/outputs.tf` exposes cluster and network outputs.
- `terraform/.terraform.lock.hcl` pins provider selections.
- `terraform-aws-modules/vpc/aws` is constrained to `~> 6.0`.
- `terraform-aws-modules/eks/aws` is constrained to `~> 21.0`.
- `hashicorp/aws` is constrained to `~> 6.0`.

Use the official modules for AWS changes instead of adding new handwritten VPC, IAM, or EKS resources to the root.

### Floci validation

The Floci validation runs the canonical `terraform/` root with `AWS_ENDPOINT_URL=http://127.0.0.1:4566`. It must not introduce a second root or a Floci-only network module.

The EKS managed node group is configured with `use_latest_ami_release_version = false`, `create_launch_template = false`, and `use_custom_launch_template = false`. This lets EKS select its default managed-node AMI and avoids the AWS SSM AMI lookup that Floci does not implement. The module graph and resources remain the same for AWS and Floci.

## Required validation

For changes under `terraform/`:

```bash
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
```

For the Floci compatibility run:

```bash
docker compose -f terraform/docker-compose.floci.yml up -d --wait

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://127.0.0.1:4566

terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
terraform -chdir=terraform plan -var-file=floci.tfvars.example
terraform -chdir=terraform apply -auto-approve -var-file=floci.tfvars.example
aws eks describe-cluster --name simpleapp-floci
aws eks describe-nodegroup \
  --cluster-name simpleapp-floci \
  --nodegroup-name simpleapp-floci-node-group
terraform -chdir=terraform destroy -auto-approve -var-file=floci.tfvars.example

docker compose -f terraform/docker-compose.floci.yml down -v --remove-orphans
```

A successful Floci test must demonstrate:

- the canonical Terraform root validates;
- the plan contains the AWS module resources;
- apply completes successfully;
- the EKS cluster status is `ACTIVE`;
- the EKS node group status is `ACTIVE`;
- destroy completes successfully;
- no test containers or Terraform state are left behind unexpectedly.

For Kubernetes manifest changes, use a disposable Kind cluster when the required tools and images are available. Do not claim Kubernetes integration success based only on YAML parsing.

For application changes, run the narrowest relevant Python test or smoke test and verify the HTTP endpoint when practical.

## Helm application deployment

The recommended Kubernetes application delivery path is `kubernetes/helm/simpleapp/`. It owns the application Deployment, Service, ConfigMap, ServiceAccount, HPA, and Ingress. The raw files under `kubernetes/manifests/` are retained as legacy/reference resources and must not be used by the deployment workflow.

Use `helm lint`, `helm template`, and `helm upgrade --install --atomic --wait` for application delivery. Publish immutable image tags based on the commit SHA. Never put a GHCR token, APM token, or other secret in `values.yaml`; use a Kubernetes Secret referenced through `apm.existingSecret` or a deployment environment secret.

The manual GitHub Actions workflow uses AWS OIDC and requires protected-environment secrets `AWS_ROLE_TO_ASSUME` and `GHCR_READ_TOKEN`. Terraform provisions EKS; Helm deploys workloads after the cluster exists.

## CI files

- `.github/workflows/terraform-ci.yaml` validates the AWS root and runs the complete Floci apply/destroy cycle.
- `.github/workflows/deploy_app.yaml` builds the application image and deploys the Helm chart manually.
- `.github/workflows/deploy_terraform.yaml` is manual-only and may apply to AWS.

Keep action versions current and use `actions/checkout@v4` and `hashicorp/setup-terraform@v3` conventions already established in the repository.

## Change workflow

1. Inspect the current files, Terraform state boundaries, workflows, and recent commits.
2. Make the smallest change that satisfies the request.
3. Run the relevant validation commands before committing.
4. Review `git diff --check`, `git status`, and the final diff.
5. Commit with one focused conventional commit.
6. Push the commit when requested or when the task explicitly requires remote delivery.
7. Verify the remote ref matches local `HEAD`:

```bash
git rev-parse HEAD
git ls-remote origin refs/heads/main
```

Never report a push as successful without checking the remote ref.
