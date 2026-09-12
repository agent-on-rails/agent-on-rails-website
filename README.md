# Agent On Rails — Marketing Website

Public marketing site for **Agent On Rails**.

- **URL:** https://agent-on-rails.suherman.net
- **Stack:** Astro 5 (static) + Express on `:8080`
- **Deploy:** Docker → GHCR → HaloRT k3s / Argo CD

## Local

```bash
npm install
npm run dev      # Astro on :4321
npm run build && npm start   # production static + health API
```

## Deploy

```bash
# 1) build + push image, pin kustomization tag
bash scripts/deploy-image.sh

# 2) commit + push so Argo can see deploy/kubernetes/...
git add deploy/kubernetes/apps/agent-on-rails-website/kustomization.yaml public/downloads
git commit -m "…" && git push

# 3) sync on HaloRT (never use default ~/.kube/config — that may be CIMB/UAT)
bash scripts/sync-argo.sh
```

`scripts/sync-argo.sh` forces `~/.kube/halort-platform/config` (or
`halort-infra/.credentials/kube/halort-platform/config`), hard-refreshes Argo,
and checks https://agent-on-rails.suherman.net/downloads/latest.json.

DNS (Cloudflare → Hetzner LB):

```bash
cd ~/src/personal/suherman-net-infra
set -a && source .env && set +a
SUBDOMAIN=agent-on-rails bash scripts/setup-cloudflare-k8s-subdomain.sh
```

## Deploy status checklist

Done:
- [x] Repo: https://github.com/agent-on-rails/agent-on-rails-website
- [x] Image: `ghcr.io/agent-on-rails/agent-on-rails-website` (tag pinned in kustomization)
- [x] DNS: `agent-on-rails.suherman.net` → Hetzner LB (Cloudflare proxied)
- [x] Argo Application committed in `HaloRT/halort-infra`

One-time / recovery (GHCR pull secret):

```bash
cd ~/src/halort/halort-infra
set -a && source .env && set +a
export KUBECONFIG="$HOME/.kube/halort-platform/config"
NAMESPACE=agent-on-rails bash scripts/sync-ghcr-pull-to-kube.sh
```

Until the Ingress is healthy, Cloudflare may show **404** on https://agent-on-rails.suherman.net.