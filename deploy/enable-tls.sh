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
OLD_DOMAIN="www.ondralinek.cz"
REPO_DIR="${REPO_DIR:-$HOME/me}"
WEB_ROOT="${WEB_ROOT:-/var/www/me}"
PUBLIC_IP="2.31.33.21"

cd "$REPO_DIR"

echo "==> checking DNS"
# Ask public resolvers: the local stub resolver may still hold the old GitHub
# Pages CNAME for up to its TTL, while Let's Encrypt validates against public
# DNS. www.ondralinek.cz is kept in the certificate so the old address can
# redirect, and it must therefore keep pointing here as well.
resolved_of() {
    local name="$1" resolved=""
    for resolver in 1.1.1.1 8.8.8.8; do
        resolved="$(dig +short +time=3 +tries=1 A "$name" "@$resolver" | grep -E '^[0-9.]+$' | head -1)"
        [ -n "$resolved" ] && break
    done
    [ -n "$resolved" ] || resolved="$(getent ahostsv4 "$name" | awk 'NR==1{print $1}')"
    printf '%s' "$resolved"
}

failed=0
for name in "$DOMAIN" "$OLD_DOMAIN"; do
    resolved="$(resolved_of "$name")"
    echo "    $name -> ${resolved:-nothing} (expected $PUBLIC_IP)"
    [ "$resolved" = "$PUBLIC_IP" ] || failed=1
done

if [ "$failed" != "0" ]; then
    cat >&2 <<EOF
ERROR: DNS is not pointing at this server yet.
       Point both names at $PUBLIC_IP first:
         A     $DOMAIN      $PUBLIC_IP
         AAAA  $DOMAIN      2a01:4f8:c016:e828::1
         A     $OLD_DOMAIN  $PUBLIC_IP
         AAAA  $OLD_DOMAIN  2a01:4f8:c016:e828::1
       ($OLD_DOMAIN is needed for the redirect and for renewals.)
EOF
    exit 1
fi

echo "==> requesting certificate for $DOMAIN, $OLD_DOMAIN"
# Webroot mode: certbot drops the challenge into the site root, which the vhost
# already serves under /.well-known/acme-challenge/. No config rewriting, so the
# versioned vhost in this repo stays the single source of truth.
sudo certbot certonly --webroot -w "$WEB_ROOT" \
    -d "$DOMAIN" -d "$OLD_DOMAIN" --cert-name "$DOMAIN" \
    --non-interactive --agree-tos --deploy-hook "systemctl reload nginx"

echo "==> switching vhost to HTTPS"
sudo install -d -o deploy -g www-data -m 0755 "$WEB_ROOT"
sudo install -m 0644 -o root -g root deploy/nginx/me.conf /etc/nginx/sites-available/me
sudo ln -sfn /etc/nginx/sites-available/me /etc/nginx/sites-enabled/me
sudo nginx -t
sudo systemctl reload nginx

echo "==> verifying"
code="$(curl -sS -o /dev/null -w '%{http_code}' --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN/")"
echo "    https://$DOMAIN/ -> $code"
redirect="$(curl -sS -o /dev/null -w '%{http_code} %{redirect_url}' --resolve "$OLD_DOMAIN:443:127.0.0.1" "https://$OLD_DOMAIN/")"
echo "    https://$OLD_DOMAIN/ -> $redirect"
redirect="$(curl -sS -o /dev/null -w '%{http_code} %{redirect_url}' --resolve "$DOMAIN:80:127.0.0.1" "http://$DOMAIN/")"
echo "    http://$DOMAIN/ -> $redirect"
