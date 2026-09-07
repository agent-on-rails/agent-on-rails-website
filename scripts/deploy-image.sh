#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

IMAGE_REPO="${IMAGE_REPO:-ghcr.io/agent-on-rails/agent-on-rails-website}"
SHA="$(git rev-parse HEAD)"
SHORT_SHA="$(git rev-parse --short HEAD)"

echo "Building ${IMAGE_REPO}:${SHA}"
docker build --platform linux/amd64 -t "${IMAGE_REPO}:${SHA}" -t "${IMAGE_REPO}:${SHORT_SHA}" -t "${IMAGE_REPO}:latest" .

echo "Pushing..."
docker push "${IMAGE_REPO}:${SHA}"
docker push "${IMAGE_REPO}:${SHORT_SHA}"
docker push "${IMAGE_REPO}:latest"

KUSTO="${ROOT}/deploy/kubernetes/apps/agent-on-rails-website/kustomization.yaml"
if command -v sed >/dev/null; then
  if grep -q 'newTag:' "$KUSTO"; then
    sed -i.bak -E "s|(newTag:).*|\\1 ${SHA}|" "$KUSTO"
    rm -f "${KUSTO}.bak"
    echo "Pinned newTag to ${SHA} in kustomization.yaml"
  fi
fi

echo "Done. Commit the kustomization pin and push so Argo can sync."
