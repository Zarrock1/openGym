#!/bin/sh
# One-shot setup of openGym on a VPS behind Caddy (automatic HTTPS).
# Usage, from the repository root:   sh deploy/vps/setup.sh gym.example.com
set -eu

cd "$(dirname "$0")/../.."

DOMAIN="${1:-}"
if [ -z "$DOMAIN" ]; then
  printf 'Domain (e.g. gym.example.com): '
  read -r DOMAIN
fi
[ -n "$DOMAIN" ] || { echo "A domain is required: passkeys need HTTPS on a real hostname." >&2; exit 1; }

command -v docker >/dev/null 2>&1 || { echo "Docker is not installed: curl -fsSL https://get.docker.com | sh" >&2; exit 1; }

if [ -f .env ]; then
  echo ".env already exists, leaving it as it is."
else
  cat > .env <<ENV
RP_ID=$DOMAIN
ORIGIN=https://$DOMAIN
# The web container is published on localhost only; Caddy is the way in from outside.
WEB_PORT=127.0.0.1:8080
RP_NAME=openGym
# The first profile created becomes admin. Create yours right after the first start.
FIRST_USER_ADMIN=1
# Once your own profile exists, uncomment both to close the instance to strangers:
# INVITE_ONLY=1
# ALLOW_GUEST=0
ENV
  echo "Wrote .env for https://$DOMAIN"
fi

mkdir -p data
docker compose -f docker-compose.yml -f deploy/vps/docker-compose.caddy.yml pull
docker compose -f docker-compose.yml -f deploy/vps/docker-compose.caddy.yml up -d

echo
echo "Done. Open https://$DOMAIN in Safari, create your profile (it becomes admin),"
echo "then Share -> Add to Home Screen."
