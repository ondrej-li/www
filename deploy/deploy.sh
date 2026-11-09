#!/usr/bin/env bash
# Publish the static site to /var/www/me.
#
#   ./deploy/deploy.sh              # git pull + publish + nginx config
#   SKIP_NGINX=1 ./deploy/deploy.sh # content only
#
# Runs on the VPS as the deploy user (member of sudo).
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/me}"
WEB_ROOT="${WEB_ROOT:-/var/www/me}"

cd "$REPO_DIR"

echo "==> fetching"
before="$(git rev-parse HEAD)"
git pull --ff-only
after="$(git rev-parse HEAD)"
# Bash reads this file incrementally, so never keep running a script that the
# pull just replaced: restart it once with the fresh copy.
if [ "$before" != "$after" ] && [ "${ME_DEPLOY_REEXEC:-0}" != "1" ]; then
    ME_DEPLOY_REEXEC=1 exec "$0" "$@"
fi

echo "==> publishing to $WEB_ROOT"
sudo install -d -o deploy -g www-data -m 0755 "$WEB_ROOT"
# Keep the ACME challenge directory: certbot renewals write into it.
rsync -a --delete \
    --exclude ".well-known/" \
    --exclude ".git/" \
    --exclude ".github/" \
    --exclude "deploy/" \
    --exclude "_scss/" \
    --exclude "CNAME" \
    "$REPO_DIR"/ "$WEB_ROOT"/
sudo chown -R deploy:www-data "$WEB_ROOT"
sudo find "$WEB_ROOT" -type d -exec chmod 755 {} +
sudo find "$WEB_ROOT" -type f -exec chmod 644 {} +

if [ "${SKIP_NGINX:-0}" = "1" ]; then
    echo "==> nginx skipped (SKIP_NGINX=1)"
    exit 0
fi

echo "==> nginx configuration"
sudo install -m 0644 -o root -g root deploy/nginx/me-headers.conf /etc/nginx/snippets/me-headers.conf

if sudo test -f /etc/letsencrypt/live/me.ondralinek.cz/fullchain.pem; then
    sudo install -m 0644 -o root -g root deploy/nginx/me.conf /etc/nginx/sites-available/me
else
    sudo install -m 0644 -o root -g root deploy/nginx/me-http.conf /etc/nginx/sites-available/me
fi

sudo ln -sfn /etc/nginx/sites-available/me /etc/nginx/sites-enabled/me
sudo nginx -t
sudo systemctl reload nginx

if [ "${SKIP_SYSTEMD:-0}" != "1" ]; then
    echo "==> auto-deploy timer"
    sudo install -m 0644 -o root -g root deploy/systemd/me-autodeploy.service /etc/systemd/system/me-autodeploy.service
    sudo install -m 0644 -o root -g root deploy/systemd/me-autodeploy.timer /etc/systemd/system/me-autodeploy.timer
    sudo systemctl daemon-reload
    sudo systemctl enable --now me-autodeploy.timer >/dev/null
fi

echo "==> done: published $(find "$WEB_ROOT" -type f | wc -l) files"
