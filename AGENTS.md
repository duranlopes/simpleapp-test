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
- an isolated Floci Terraform root under `terraform/floci/`.

The AWS Terraform root and the Floci test root are intentionally separate. Do not point the AWS root at Floci or point production credentials at the Floci root.

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

### Floci root

The compatibility root is `terraform/floci/`:

- It uses only AWS resources supported by the Floci compatibility test.
- `terraform/modules/floci-network` creates the minimal VPC, subnet, and security-group resources needed to obtain valid IDs.
- It uses Floci mock EKS mode for deterministic CI.
- It must remain state-isolated from `terraform/`.

The official EKS module may query AWS SSM for optimized node AMIs. That is valid for AWS but is not available in Floci; do not make the Floci job pretend to validate the full AWS module graph.

## Required validation

For changes under `terraform/`:

```bash
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
```

For changes under `terraform/floci/`:

```bash
docker compose -f terraform/docker-compose.floci.yml up -d --wait

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://127.0.0.1:4566

terraform -chdir=terraform/floci fmt -check -recursive
terraform -chdir=terraform/floci init -backend=false -input=false
terraform -chdir=terraform/floci validate
terraform -chdir=terraform/floci plan -var-file=../floci.tfvars.example
terraform -chdir=terraform/floci apply -auto-approve -var-file=../floci.tfvars.example
terraform -chdir=terraform/floci output
terraform -chdir=terraform/floci destroy -auto-approve -var-file=../floci.tfvars.example

docker compose -f terraform/docker-compose.floci.yml down -v
```

A successful Floci test must demonstrate:

- Terraform validation succeeds;
- the plan contains the expected resources;
- apply completes successfully;
- `cluster_status` is `ACTIVE`;
- `node_group_status` is `ACTIVE`;
- destroy completes successfully;
- no test containers or Terraform state are left behind unexpectedly.

For Kubernetes manifest changes, use a disposable Kind cluster when the required tools and images are available. Do not claim Kubernetes integration success based only on YAML parsing.

For application changes, run the narrowest relevant Python test or smoke test and verify the HTTP endpoint when practical.

## CI files

- `.github/workflows/terraform-ci.yaml` validates the AWS root and runs the complete Floci apply/destroy cycle.
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
