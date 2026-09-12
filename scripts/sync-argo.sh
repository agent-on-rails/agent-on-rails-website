#!/usr/bin/env bash
# Sync / verify the Agent On Rails website on HaloRT k3s (Argo CD).
#
# IMPORTANT: do NOT use the default ~/.kube/config — that often points at an
# unrelated cluster (e.g. CIMB UAT at 172.16.0.2). Always prefer HaloRT.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${ARGO_APP:-agent-on-rails-website}"
NS="${ARGO_NAMESPACE:-agent-on-rails}"
HALORT_INFRA="${HALORT_INFRA_ROOT:-$HOME/src/halort/halort-infra}"
LIVE_URL="${AOR_LIVE_URL:-https://agent-on-rails.suherman.net}"

resolve_kubeconfig() {
  local candidates=()
  if [[ -n "${HALORT_KUBECONFIG:-}" ]]; then
    candidates+=("$HALORT_KUBECONFIG")
  fi
  candidates+=(
    "$HOME/.kube/halort-platform/config"
    "$HALORT_INFRA/.credentials/kube/halort-platform/config"
  )
  # Only accept an explicit KUBECONFIG if it looks like HaloRT (not CIMB/GKE private IPs).
  if [[ -n "${KUBECONFIG:-}" ]]; then
    candidates+=("$KUBECONFIG")
  fi

  local cand server
  for cand in "${candidates[@]}"; do
    [[ -f "$cand" ]] || continue
    server="$(KUBECONFIG="$cand" kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null || true)"
    # Reject known non-HaloRT private API endpoints that previously caused silent hangs.
    if [[ "$server" == *"172.16.0.2"* ]]; then
      echo "Skipping $cand (looks like CIMB UAT, not HaloRT): $server" >&2
      continue
    fi
    if KUBECONFIG="$cand" kubectl --request-timeout=8s get ns kube-system -o name >/dev/null 2>&1; then
      echo "$cand"
      return 0
    fi
    echo "Skipping unreachable kubeconfig $cand ($server)" >&2
  done
  return 1
}

if ! KUBE="$(resolve_kubeconfig)"; then
  echo "No reachable HaloRT kubeconfig found." >&2
  echo "Tried: \$HALORT_KUBECONFIG, ~/.kube/halort-platform/config, halort-infra credentials." >&2
  echo "Default kubectl context is often a different cluster — do not rely on it." >&2
  exit 1
fi

export KUBECONFIG="$KUBE"
SERVER="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
echo "==> Using HaloRT kubeconfig: $KUBECONFIG"
echo "    API: $SERVER"

echo "==> Application status"
kubectl -n argocd get application "$APP" -o wide

echo "==> Hard-refresh Argo"
kubectl -n argocd annotate application "$APP" argocd.argoproj.io/refresh=hard --overwrite >/dev/null

# Prefer sync if OutOfSync; otherwise wait for Healthy.
STATUS="$(kubectl -n argocd get application "$APP" -o jsonpath='{.status.sync.status}')"
if [[ "$STATUS" != "Synced" ]]; then
  echo "==> Syncing ($STATUS → Synced)"
  if command -v argocd >/dev/null 2>&1; then
    argocd app sync "$APP" --prune --timeout 180 || true
  else
    kubectl -n argocd patch application "$APP" --type merge \
      -p '{"operation":{"initiatedBy":{"username":"aor-sync"},"sync":{"revision":"HEAD"}}}' || true
  fi
fi

echo "==> Waiting for Healthy + Synced"
for i in $(seq 1 36); do
  SYNC="$(kubectl -n argocd get application "$APP" -o jsonpath='{.status.sync.status}')"
  HEALTH="$(kubectl -n argocd get application "$APP" -o jsonpath='{.status.health.status}')"
  REV="$(kubectl -n argocd get application "$APP" -o jsonpath='{.status.sync.revision}')"
  echo "    [$i] sync=$SYNC health=$HEALTH rev=${REV:0:7}"
  if [[ "$SYNC" == "Synced" && "$HEALTH" == "Healthy" ]]; then
    break
  fi
  sleep 5
done

echo "==> Workload"
kubectl -n "$NS" get pods,ingress -o wide

echo "==> Live check"
LIVE_JSON="$(curl -fsS "$LIVE_URL/downloads/latest.json")"
LIVE_VER="$(printf '%s' "$LIVE_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin)["version"])')"
echo "    $LIVE_URL → version $LIVE_VER"
EXPECTED="$(python3 -c 'import json,pathlib; print(json.loads(pathlib.Path("'"$ROOT"'/public/downloads/latest.json").read_text())["version"])' 2>/dev/null || true)"
if [[ -n "$EXPECTED" && "$LIVE_VER" != "$EXPECTED" ]]; then
  echo "WARN: live $LIVE_VER != repo latest.json $EXPECTED (CDN/cache may lag briefly)" >&2
  exit 2
fi
echo "Done."
