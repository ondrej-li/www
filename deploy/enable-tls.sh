#!/usr/bin/env bash
# One-off cutover step: request the Let's Encrypt certificate and switch the
# vhost to HTTPS. Run it only after me.ondralinek.cz resolves to this server.
#
#   ./deploy/enable-tls.sh
#
# Renewals afterwards are handled by certbot.timer; the global deploy hook
# (/etc/letsencrypt/renewal-hooks/deploy/10-mail.sh) reloads nginx.
set -euo pipefail

DOMAIN="me.ondralinek.cz"
REPO_DIR="${REPO_DIR:-$HOME/me}"
WEB_ROOT="${WEB_ROOT:-/var/www/me}"
PUBLIC_IP="2.31.33.21"

cd "$REPO_DIR"

echo "==> checking DNS"
# Ask public resolvers: the local stub resolver may still hold an old answer
# for up to its TTL, while Let's Encrypt validates against public DNS.
# www.ondralinek.cz belongs to the landing site and is not part of this
# certificate any more.
resolved_of() {
    local name="$1" resolved=""
    for resolver in 1.1.1.1 8.8.8.8; do
        resolved="$(dig +short +time=3 +tries=1 A "$name" "@$resolver" | grep -E '^[0-9.]+$' | head -1)"
        [ -n "$resolved" ] && break
    done
    [ -n "$resolved" ] || resolved="$(getent ahostsv4 "$name" | awk 'NR==1{print $1}')"
    printf '%s' "$resolved"
}

resolved="$(resolved_of "$DOMAIN")"
echo "    $DOMAIN -> ${resolved:-nothing} (expected $PUBLIC_IP)"

if [ "$resolved" != "$PUBLIC_IP" ]; then
    cat >&2 <<EOF
ERROR: DNS is not pointing at this server yet.
       Point $DOMAIN at $PUBLIC_IP first:
         A     $DOMAIN  $PUBLIC_IP
         AAAA  $DOMAIN  2a01:4f8:c016:e828::1
EOF
    exit 1
fi

echo "==> requesting certificate for $DOMAIN"
# Webroot mode: certbot drops the challenge into the site root, which the vhost
# already serves under /.well-known/acme-challenge/. No config rewriting, so the
# versioned vhost in this repo stays the single source of truth.
sudo certbot certonly --webroot -w "$WEB_ROOT" \
    -d "$DOMAIN" --cert-name "$DOMAIN" \
    --non-interactive --agree-tos --deploy-hook "systemctl reload nginx"

echo "==> switching vhost to HTTPS"
sudo install -d -o deploy -g www-data -m 0755 "$WEB_ROOT"
sudo install -m 0644 -o root -g root deploy/nginx/me.conf /etc/nginx/sites-available/me
sudo ln -sfn /etc/nginx/sites-available/me /etc/nginx/sites-enabled/me
sudo nginx -t
sudo systemctl reload nginx

echo "==> verifying"
# nginx picks the new config up a moment after `systemctl reload`, so give the
# reload a few seconds before failing the cutover.
code=""
for _ in 1 2 3 4 5; do
    code="$(curl -sS -o /dev/null -w '%{http_code}' --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN/" 2>/dev/null || true)"
    [ "$code" = "200" ] && break
    sleep 1
done
echo "    https://$DOMAIN/ -> ${code:-no response}"
if [ "$code" != "200" ]; then
    echo "ERROR: HTTPS did not come up; the certificate is installed but the vhost is not healthy." >&2
    exit 1
fi
redirect="$(curl -sS -o /dev/null -w '%{http_code} %{redirect_url}' --resolve "$DOMAIN:80:127.0.0.1" "http://$DOMAIN/")"
echo "    http://$DOMAIN/ -> $redirect"
