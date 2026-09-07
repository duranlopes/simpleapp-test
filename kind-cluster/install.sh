#!/usr/bin/env bash
set -euo pipefail

KIND_VERSION="${KIND_VERSION:-v0.27.0}"
CLUSTER_NAME="${KIND_CLUSTER_NAME:-simpleapp}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v kind >/dev/null 2>&1; then
  tmp_kind="$(mktemp)"
  trap 'rm -f "$tmp_kind"' EXIT
  curl --fail --location --silent --show-error \
    --output "$tmp_kind" \
    "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64"
  chmod 0755 "$tmp_kind"
  sudo install -m 0755 "$tmp_kind" /usr/local/bin/kind
fi

if ! kind get clusters | grep -qx "$CLUSTER_NAME"; then
  kind create cluster \
    --name "$CLUSTER_NAME" \
    --config "$SCRIPT_DIR/kind-config.yaml"
fi

kubectl apply \
  --filename "https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml"
kubectl wait \
  --namespace ingress-nginx \
  --for=condition=available deployment/ingress-nginx-controller \
  --timeout=180s
kubectl apply --filename "$SCRIPT_DIR/metric-server.yaml"
