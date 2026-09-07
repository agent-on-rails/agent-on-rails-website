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

GHCR pull secret into namespace:

```bash
cd ~/src/halort/halort-infra
NAMESPACE=agent-on-rails bash scripts/sync-ghcr-pull-to-kube.sh
```
