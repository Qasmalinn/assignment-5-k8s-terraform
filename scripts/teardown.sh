#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------
# teardown.sh
# Unregisters the GitHub Actions runner and deletes the Kind cluster.
# Run this manually — Terraform local-exec provisioners do not
# execute on destroy.
#
# Usage:
#   GITHUB_REPO=owner/repo RUNNER_TOKEN=<token> bash scripts/teardown.sh
# ------------------------------------------------------------------

CLUSTER_NAME="assignment-5"

echo "==> Starting teardown..."

# -------------------------------------------------------
# 1. Stop and unregister the GitHub Actions runner
# -------------------------------------------------------
RUNNER_DIR="${HOME}/actions-runner"

if [ -d "$RUNNER_DIR" ]; then
  echo "==> Stopping runner service..."
  pushd "$RUNNER_DIR" > /dev/null
    sudo ./svc.sh stop   2>/dev/null || true
    sudo ./svc.sh uninstall 2>/dev/null || true
  popd > /dev/null

  if [ -n "${RUNNER_TOKEN:-}" ] && [ -n "${GITHUB_REPO:-}" ]; then
    echo "==> Unregistering runner from GitHub..."
    "${RUNNER_DIR}/config.sh" remove \
      --token "${RUNNER_TOKEN}" || true
  else
    echo "==> RUNNER_TOKEN or GITHUB_REPO not set, skipping GitHub unregistration"
    echo "    You can remove the runner manually at:"
    echo "    https://github.com/<owner>/<repo>/settings/actions/runners"
  fi

  rm -rf "$RUNNER_DIR"
  echo "==> Runner directory removed"
else
  echo "==> No runner directory found at ${RUNNER_DIR}, skipping"
fi

# -------------------------------------------------------
# 2. Delete Kind cluster
# -------------------------------------------------------
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
  echo "==> Deleting Kind cluster '${CLUSTER_NAME}'..."
  kind delete cluster --name "$CLUSTER_NAME"
else
  echo "==> Kind cluster '${CLUSTER_NAME}' not found, skipping"
fi

echo "==> Teardown complete"
