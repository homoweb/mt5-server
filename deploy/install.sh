#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="$BASE_DIR/deploy"
NGINX_TEMPLATE="$BASE_DIR/nginx/mt5.conf.template"
ENV_FILE="$DEPLOY_DIR/.env"

read -rp "Enter your domain (e.g. trade.nexaping.tr): " DOMAIN
read -rp "Enter your email for SSL (e.g. admin@nexaping.tr): " EMAIL
read -rp "Enter API Secret Token (Press Enter for auto-generated): " USER_API_SECRET

if [[ -z "${DOMAIN:-}" || -z "${EMAIL:-}" ]]; then
  echo "Error: DOMAIN and EMAIL are required."
  exit 1
fi

if [[ -z "${USER_API_SECRET:-}" ]]; then
  API_SECRET="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)"
else
  API_SECRET="$USER_API_SECRET"
fi

echo "=== 1) Install system dependencies ==="
sudo apt update
sudo apt install -y \
  curl wget nginx certbot python3-certbot-nginx \
  ca-certificates gnupg lsb-release net-tools

echo "=== 2) Install Docker (if missing) ==="
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sudo sh /tmp/get-docker.sh
  rm -f /tmp/get-docker.sh
fi
sudo apt install -y docker-compose-plugin

echo "=== 3) Prepare project runtime files ==="
mkdir -p "$BASE_DIR/mt5_data"

if [[ ! -f "$BASE_DIR/mt5setup.exe" ]]; then
  wget -O "$BASE_DIR/mt5setup.exe" \
    "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"
fi

echo "=== 4) Write deploy/.env ==="
cat > "$ENV_FILE" <<EOF
API_SECRET=${API_SECRET}
EOF
chmod 600 "$ENV_FILE"

echo "=== 5) Docker compose up ==="
cd "$DEPLOY_DIR"
sudo docker compose down || true
sudo docker compose build --no-cache
sudo docker compose up -d

echo "=== 6) Configure Nginx from template ==="
if [[ ! -f "$NGINX_TEMPLATE" ]]; then
  echo "Error: Nginx template not found: $NGINX_TEMPLATE"
  exit 1
fi

TMP_NGINX_CONF="$(mktemp)"
sed "s|__DOMAIN__|$DOMAIN|g" "$NGINX_TEMPLATE" > "$TMP_NGINX_CONF"

sudo cp "$TMP_NGINX_CONF" "/etc/nginx/sites-available/$DOMAIN"
rm -f "$TMP_NGINX_CONF"

sudo ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/$DOMAIN"
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

echo "=== 7) Issue SSL ==="
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" || true

echo "=== 8) Health checks ==="
sleep 3
curl -sS -o /dev/null -w "openapi local status: %{http_code}\n" http://127.0.0.1:8000/openapi.json || true
curl -sS -o /dev/null -w "docs local status: %{http_code}\n" http://127.0.0.1:8000/docs || true

echo "=== DONE ==="
echo "API Token: $API_SECRET"
echo "Docs: https://$DOMAIN/docs"
echo "VNC : https://$DOMAIN/"
