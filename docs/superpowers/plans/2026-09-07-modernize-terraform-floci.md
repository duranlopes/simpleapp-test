# Modernize Terraform and Floci Validation Implementation Plan

> **For agentic workers:** Execute this plan task-by-task with verification and a separate commit after each completed task.

**Goal:** Modernize `simpleapp-test` Terraform to current AWS modules/providers and validate the EKS configuration against Floci without weakening the real AWS deployment path.

**Architecture:** Use the official VPC and EKS community modules for the AWS implementation. Keep Floci validation in a separate Terraform root so emulator-specific endpoint and feature flags cannot affect production AWS state. CI will run static checks and a Floci plan/mock validation; real AWS apply remains manual.

**Tech Stack:** Terraform 1.15.x, AWS provider 6.x, `terraform-aws-modules/vpc/aws` 6.x, `terraform-aws-modules/eks/aws` 21.x, Floci Docker image, tflint, GitHub Actions.

## Global Constraints

- All repository artifacts remain in English.
- Every completed adjustment gets its own conventional commit and is pushed to `origin/main`.
- No AWS credentials or private state are committed.
- Floci tests must not run against real AWS endpoints.
- Real AWS apply remains manual and must not be part of pull-request validation.
- Provider and module versions must be constrained and locked.

---

### Task 1: Add the implementation plan

**Files:**
- Create: `docs/superpowers/plans/2026-09-07-modernize-terraform-floci.md`

- [ ] Verify the plan contains all requested work and explicit commit boundaries.
- [ ] Commit as `docs(terraform): add modernization and Floci plan`.
- [ ] Push and verify the remote branch points at the new commit.

### Task 2: Modernize Terraform root and variables

**Files:**
- Modify: `terraform/provider.tf`
- Modify: `terraform/variables.tf`
- Modify: `terraform/modules.tf`
- Create: `terraform/versions.tf` if root configuration is split by responsibility.
- Generate: `terraform/.terraform.lock.hcl`

- [ ] Require Terraform 1.9 or newer and constrain `hashicorp/aws` to `~> 6.0`.
- [ ] Add explicit variable types, descriptions, and validation for region, Kubernetes version, and node sizing.
- [ ] Preserve the existing variable names where compatibility is useful.
- [ ] Run `terraform fmt -recursive`, `terraform init -backend=false`, and `terraform validate`.
- [ ] Commit as `refactor(terraform): modernize Terraform and AWS provider`.
- [ ] Push and verify the remote branch.

### Task 3: Replace handwritten VPC resources with the official VPC module

**Files:**
- Remove or stop referencing: `terraform/modules/network/*.tf`
- Modify: `terraform/modules.tf`
- Modify: `terraform/outputs.tf` if required.
- Modify: `terraform/variables.tf` for VPC and subnet inputs.

- [ ] Use `terraform-aws-modules/vpc/aws` with a pinned 6.x version.
- [ ] Preserve two public and two private subnets in two availability zones.
- [ ] Preserve EKS subnet tags and NAT behavior.
- [ ] Expose VPC and private subnet IDs through stable root outputs.
- [ ] Run formatting, initialization, validation, and a no-refresh plan.
- [ ] Commit as `refactor(terraform): adopt official VPC module`.
- [ ] Push and verify the remote branch.

### Task 4: Replace handwritten EKS/IAM resources with the official EKS module

**Files:**
- Remove or stop referencing: `terraform/modules/master/*.tf`
- Remove or stop referencing: `terraform/modules/node/*.tf`
- Modify: `terraform/modules.tf`
- Create or modify: `terraform/outputs.tf`

- [ ] Use `terraform-aws-modules/eks/aws` with a pinned 21.x version.
- [ ] Configure a managed node group with the existing desired/min/max variables.
- [ ] Keep the cluster name and Kubernetes version configurable.
- [ ] Disable optional addons/access-entry features that Floci does not implement unless required by the AWS path.
- [ ] Preserve kubeconfig-relevant cluster endpoint and certificate outputs.
- [ ] Run formatting, initialization, validation, and a no-refresh plan.
- [ ] Commit as `refactor(terraform): adopt official EKS module`.
- [ ] Push and verify the remote branch.

### Task 5: Validate the canonical Terraform root with Floci

**Files:**
- Create: `terraform/docker-compose.floci.yml`
- Create: `terraform/floci.tfvars.example`
- Modify: `terraform/modules.tf`
- Modify: `.github/workflows/terraform-ci.yaml`
- Modify: `README.md`
- Modify: `AGENTS.md`

- [ ] Configure Floci through `AWS_ENDPOINT_URL` and test-only credentials.
- [ ] Run the same `terraform/` root against Floci; do not create a second root or Floci-only network module.
- [ ] Disable only module operations unavailable in Floci while preserving the AWS module graph.
- [ ] Run Floci in Docker, wait for health, and run root `terraform init`, `validate`, `plan`, `apply`, API assertions, and `destroy`.
- [ ] Commit and push the canonical-root Floci validation change.

### Task 6: Modernize Terraform CI and documentation

**Files:**
- Modify: `.github/workflows/deploy_terraform.yaml`
- Create: `.github/workflows/terraform-ci.yaml`
- Modify: `README.md`
- Create: `terraform/README.md` if needed.

- [ ] Upgrade GitHub Actions to current major versions.
- [ ] Add static Terraform checks and Floci plan validation.
- [ ] Keep AWS deployment manual and remove `continue-on-error` from plan validation.
- [ ] Document AWS apply, Floci validation, state requirements, and known emulator limits.
- [ ] Run all local checks and inspect the final diff.
- [ ] Commit as `ci(terraform): validate Terraform against Floci` and `docs(terraform): document AWS and Floci workflows` as separate commits.
- [ ] Push each commit and verify `origin/main` after each push.

## Final Verification

- [ ] `terraform fmt -check -recursive`
- [ ] `terraform init -backend=false`
- [ ] `terraform validate`
- [ ] `terraform plan -refresh=false` for the AWS root with no credentials required for planning
- [ ] Floci starts and passes health check
- [ ] Floci Terraform root validates and produces a plan
- [ ] `git status --short` is clean
- [ ] `git log --oneline` shows one commit per adjustment
- [ ] `git ls-remote origin refs/heads/main` equals local `HEAD`
