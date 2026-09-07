SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

TERRAFORM_DIR := terraform
FLOCI_COMPOSE := $(TERRAFORM_DIR)/docker-compose.floci.yml
FLOCI_VARS := $(TERRAFORM_DIR)/floci.tfvars.example
FLOCI_ENDPOINT ?= http://127.0.0.1:4566
FLOCI_REGION ?= us-east-1
FLOCI_CLUSTER ?= simpleapp-floci
FLOCI_NODEGROUP ?= simpleapp-floci-node-group
KIND_CLUSTER ?= simpleapp-test
KIND_CONFIG := kind-cluster/kind-config.yaml
K8S_MANIFESTS := kubernetes/manifests
APP_COMPOSE := app/docker-compose.yaml

TF := terraform -chdir=$(TERRAFORM_DIR)
FLOCI_ENV := AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=$(FLOCI_REGION) AWS_ENDPOINT_URL=$(FLOCI_ENDPOINT)
TF_COMMON := -input=false -lock=false

.PHONY: help fmt init validate plan apply destroy \
        floci-up floci-wait floci-down floci-init floci-plan floci-apply \
        floci-destroy test-floci \
        app-up app-down app-config app-test \
        kind-up kind-down k8s-apply k8s-delete \
        test clean

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

fmt: ## Format Terraform files
	$(TF) fmt -recursive

init: ## Initialize the canonical Terraform root without a backend
	$(TF) init -backend=false -input=false

validate: init ## Validate the canonical Terraform root
	$(TF) validate

plan: validate ## Create a Terraform plan for AWS (no apply)
	$(TF) plan -input=false

apply: ## Apply Terraform to AWS (explicit; requires real AWS credentials)
	@test -n "$(AWS_PROFILE)$(AWS_ACCESS_KEY_ID)" || { echo "Set AWS_PROFILE or AWS_ACCESS_KEY_ID before make apply" >&2; exit 1; }
	$(TF) apply -input=false

destroy: ## Destroy Terraform resources in AWS (explicit; requires real AWS credentials)
	@test -n "$(AWS_PROFILE)$(AWS_ACCESS_KEY_ID)" || { echo "Set AWS_PROFILE or AWS_ACCESS_KEY_ID before make destroy" >&2; exit 1; }
	$(TF) destroy -input=false

floci-up: ## Start the local Floci AWS emulator
	docker compose -f $(FLOCI_COMPOSE) up -d --wait

floci-wait: ## Wait until Floci reports healthy
	@for attempt in $$(seq 1 30); do \
		if curl --fail --silent $(FLOCI_ENDPOINT)/_floci/health >/dev/null; then \
			echo "Floci is ready"; exit 0; \
		fi; \
		sleep 2; \
	done; \
	echo "Floci did not become ready" >&2; exit 1

floci-down: ## Stop and remove Floci containers and volumes
	docker compose -f $(FLOCI_COMPOSE) down -v --remove-orphans

floci-init: floci-up floci-wait ## Initialize Terraform for Floci
	$(FLOCI_ENV) $(TF) init -backend=false -input=false

floci-plan: floci-init ## Plan the canonical Terraform root against Floci
	$(FLOCI_ENV) $(TF) plan $(TF_COMMON) -refresh=false -var-file=floci.tfvars.example

floci-apply: floci-init ## Apply the canonical Terraform root against Floci
	$(FLOCI_ENV) $(TF) apply -auto-approve $(TF_COMMON) -var-file=floci.tfvars.example

floci-destroy: ## Destroy the Floci Terraform state and resources
	$(FLOCI_ENV) $(TF) destroy -auto-approve $(TF_COMMON) -var-file=floci.tfvars.example

test-floci: ## Run the complete Floci plan/apply/API/destroy cycle
	@set -e; \
	trap '$(MAKE) floci-destroy >/dev/null 2>&1 || true; $(MAKE) floci-down >/dev/null 2>&1 || true' EXIT; \
	$(MAKE) floci-plan; \
	$(MAKE) floci-apply; \
	test "$$($(FLOCI_ENV) aws eks describe-cluster --name $(FLOCI_CLUSTER) --query cluster.status --output text)" = ACTIVE; \
	test "$$($(FLOCI_ENV) aws eks describe-nodegroup --cluster-name $(FLOCI_CLUSTER) --nodegroup-name $(FLOCI_NODEGROUP) --query nodegroup.status --output text)" = ACTIVE; \
	$(MAKE) floci-destroy; \
	trap - EXIT; \
	$(MAKE) floci-down

app-config: ## Validate the application Docker Compose file
	docker compose -f $(APP_COMPOSE) config -q

app-up: ## Start the application Docker Compose stack
	docker compose -f $(APP_COMPOSE) up -d

app-down: ## Stop and remove the application Docker Compose stack
	docker compose -f $(APP_COMPOSE) down --remove-orphans

app-test: app-config ## Run a lightweight application source smoke test
	python3 -m compileall -q app

kind-up: ## Create the disposable Kind cluster and install local add-ons
	kind create cluster --name $(KIND_CLUSTER) --config $(KIND_CONFIG)
	kubectl apply -f kind-cluster/ingress-nginx-deploy.yaml
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
	kubectl apply -f kind-cluster/metric-server.yaml

kind-down: ## Delete the disposable Kind cluster
	kind delete cluster --name $(KIND_CLUSTER)

k8s-apply: ## Apply application manifests to the current Kubernetes context
	kubectl apply -f $(K8S_MANIFESTS)

k8s-delete: ## Delete application manifests from the current Kubernetes context
	kubectl delete -f $(K8S_MANIFESTS) --ignore-not-found

test: fmt validate app-test ## Run static Terraform and application checks

clean: ## Remove local Terraform artifacts and Python bytecode
	find $(TERRAFORM_DIR) -type d -name .terraform -prune -exec rm -rf {} +
	find app -type d -name __pycache__ -prune -exec rm -rf {} +
	test ! -e $(TERRAFORM_DIR)/terraform.tfstate
	test ! -e $(TERRAFORM_DIR)/terraform.tfstate.backup
