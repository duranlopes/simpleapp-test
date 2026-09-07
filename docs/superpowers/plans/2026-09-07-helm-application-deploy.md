# Helm Application Deployment Implementation Plan

> **For agentic workers:** Implement the tasks in order and validate each task before committing.

**Goal:** Replace direct Kubernetes application deployment with a versioned Helm chart and an idempotent `helm upgrade --install` workflow.

**Architecture:** The chart under `kubernetes/helm/simpleapp/` owns the application Deployment, Service, ConfigMap, Ingress, and HPA. Terraform/EKS provisioning remains separate. GitHub Actions builds an immutable image tag, configures EKS with OIDC, and deploys the chart with Helm.

**Tech Stack:** Helm 3, Kubernetes `apps/v1`, `networking.k8s.io/v1`, `autoscaling/v2`, GitHub Actions, GHCR.

## Global Constraints

- Keep AWS infrastructure deployment separate from application deployment.
- Use immutable image tags based on the commit SHA.
- Keep credentials out of files and image values.
- Preserve the existing `prova` namespace as the default.
- Validate with `helm lint`, `helm template`, YAML parsing, and workflow syntax parsing.

## Tasks

### Task 1: Create the application Helm chart

Create `kubernetes/helm/simpleapp/Chart.yaml`, `values.yaml`, `templates/_helpers.tpl`, `templates/configmap.yaml`, `templates/deployment.yaml`, `templates/service.yaml`, `templates/ingress.yaml`, and `templates/hpa.yaml`. Configure production-safe defaults: non-root security context, health probes, resource requests/limits, immutable image tag override, and HPA v2.

### Task 2: Integrate Helm into the manual deployment workflow

Modify `.github/workflows/deploy_app.yaml` to install Helm, create/update an optional GHCR pull secret from a GitHub environment secret, validate the chart, and run `helm upgrade --install --atomic --wait` instead of applying raw application manifests.

### Task 3: Integrate Helm into local workflows and documentation

Add Makefile targets for `helm-lint`, `helm-template`, `helm-install`, and `helm-uninstall`. Update README and AGENTS with chart usage, required deployment secrets, and the boundary between Helm application delivery and Terraform EKS provisioning.

### Task 4: Verify and deliver

Run Helm lint/template, YAML parsing, Makefile checks, application smoke tests, `git diff --check`, commit each coherent change, push it, and verify local/remote HEAD equality.
