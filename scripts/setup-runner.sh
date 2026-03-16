#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------
# setup-runner.sh
# Creates a Kind cluster and registers a GitHub Actions self-hosted
# runner. Called by Terraform via local-exec.
#
# Required environment variables:
#   GITHUB_REPO    — owner/repo format
#   RUNNER_TOKEN   — GitHub runner registration token
# ------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLUSTER_NAME="assignment-5"

echo "==> Starting setup..."

# -------------------------------------------------------
# 1. Create Kind cluster
# -------------------------------------------------------
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "==> Kind cluster '${CLUSTER_NAME}' already exists, skipping creation"
else
  echo "==> Creating Kind cluster '${CLUSTER_NAME}'..."
  kind create cluster \
    --name "$CLUSTER_NAME" \
    --config "${REPO_ROOT}/k8s/kind-config.yaml"
fi

# Wait for the node to be ready
echo "==> Waiting for cluster node to be ready..."
kubectl config use-context "kind-${CLUSTER_NAME}"
until kubectl get nodes | grep -q " Ready"; do
  sleep 2
done
echo "==> Cluster node is ready"

# -------------------------------------------------------
# 2. Register GitHub Actions runner
# -------------------------------------------------------
RUNNER_DIR="${HOME}/actions-runner"
RUNNER_VERSION="2.332.0"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  RUNNER_ARCH="x64" ;;
  aarch64) RUNNER_ARCH="arm64" ;;
  arm64)   RUNNER_ARCH="arm64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
# GitHub Actions runner uses "osx" instead of "darwin" for macOS
if [ "$OS" = "darwin" ]; then
  OS="osx"
fi

echo "==> Setting up GitHub Actions runner (${OS}/${RUNNER_ARCH})..."

mkdir -p "$RUNNER_DIR"

# Download runner if not already present
if [ ! -f "${RUNNER_DIR}/config.sh" ]; then
  RUNNER_TAR="actions-runner-${OS}-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
  curl -sL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_TAR}" \
    -o "${RUNNER_DIR}/${RUNNER_TAR}"
  tar xzf "${RUNNER_DIR}/${RUNNER_TAR}" -C "$RUNNER_DIR"
  rm -f "${RUNNER_DIR}/${RUNNER_TAR}"
fi

# Configure the runner
"${RUNNER_DIR}/config.sh" \
  --url "https://github.com/${GITHUB_REPO}" \
  --token "${RUNNER_TOKEN}" \
  --labels "self-hosted,local,kind" \
  --name "kind-runner" \
  --unattended \
  --replace

# Start the runner — try as a service first, fall back to background process
echo "==> Starting the runner..."
pushd "$RUNNER_DIR" > /dev/null
  if sudo ./svc.sh install 2>/dev/null && sudo ./svc.sh start 2>/dev/null; then
    echo "==> Runner installed as a system service"
  else
    echo "==> Could not install as service (sudo may not be available)"
    echo "==> Starting runner as a background process instead..."
    nohup ./run.sh > runner.log 2>&1 &
    sleep 3
    if kill -0 $! 2>/dev/null; then
      echo "==> Runner started in background (PID $!)"
    else
      echo "==> WARNING: Runner failed to start. Run it manually with:"
      echo "    cd $RUNNER_DIR && ./run.sh"
    fi
  fi
popd > /dev/null

echo ""
echo "==> Setup complete!"
echo "    Cluster: ${CLUSTER_NAME}"
echo "    Runner:  ${RUNNER_DIR}"
echo "    Labels:  self-hosted, local, kind"
