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
# build + push image, pin kustomization tag
bash scripts/deploy-image.sh

# then commit + push so Argo syncs deploy/kubernetes/...
```

DNS (Cloudflare → Hetzner LB):

```bash
cd ~/src/personal/suherman-net-infra
set -a && source .env && set +a
SUBDOMAIN=agent-on-rails bash scripts/setup-cloudflare-k8s-subdomain.sh
```

## Deploy status checklist

Done:
- [x] Repo: https://github.com/agent-on-rails/agent-on-rails-website
- [x] Image: `ghcr.io/agent-on-rails/agent-on-rails-website:62f2b1d…`
- [x] DNS: `agent-on-rails.suherman.net` → Hetzner LB (Cloudflare proxied)
- [x] Argo Application committed in `HaloRT/halort-infra`

When the HaloRT kube API is reachable (VPN / office network):

```bash
cd ~/src/halort/halort-infra
set -a && source .env && set +a
export KUBECONFIG="${KUBECONFIG/#.credentials/$PWD/.credentials}"

# Pull secret for private GHCR package
NAMESPACE=agent-on-rails bash scripts/sync-ghcr-pull-to-kube.sh

# If Argo cannot fetch the private website repo, register it (same pattern as other private orgs)
# then hard-refresh the Application in Argo CD UI: agent-on-rails-website
kubectl -n argocd get application agent-on-rails-website
kubectl -n agent-on-rails get pods,ingress
```

Until the Ingress is healthy, Cloudflare may show **404** on https://agent-on-rails.suherman.net.