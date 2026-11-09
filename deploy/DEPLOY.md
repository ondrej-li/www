# me.ondralinek.cz

Static personal site: plain HTML, CSS, JS and images. No build step, no PHP,
no database — nginx serves the files, the source lives in git and the VPS
publishes it.

| | |
|---|---|
| Host | me.ondralinek.cz (`www.ondralinek.cz` now serves the landing page) |
| Web root | `/var/www/me` (deploy:www-data) |
| Source checkout | `~/me` (deploy user, clone of github.com/ondrej-li/www) |
| vhost | `/etc/nginx/sites-available/me` → `sites-enabled/me` |
| headers | `/etc/nginx/snippets/me-headers.conf` (HSTS + CSP + …) |
| TLS | `/etc/letsencrypt/live/me.ondralinek.cz/` (SAN: me) |
| renewal | `certbot.timer`; deploy hook reloads nginx |
| logs | `/var/log/nginx/me.access.log`, `me.error.log` |
| auto-deploy | `me-autodeploy.timer` (5 min) → `deploy/autodeploy.sh` |

Everything nginx-related is versioned in this repository under `deploy/`; the
server copies are installed by `deploy/deploy.sh`.

## Deploy an update

On the VPS, as `deploy`:

```bash
cd ~/me
./deploy/deploy.sh                 # git pull, publish, nginx config
SKIP_NGINX=1 ./deploy/deploy.sh    # content only
```

The web root is replaced with `rsync --delete`, so anything that must survive a
deploy belongs outside `/var/www/me`.

## Automatic deploys

`me-autodeploy.timer` runs `deploy/autodeploy.sh` every 5 minutes:

1. `git fetch`
2. new commit → `deploy/deploy.sh` (pull, rsync, reload nginx if needed)
3. no new commit → no-op

A failed deploy leaves the previous content live and is mailed to
`admin@ondralinek.cz` (at most once per commit per hour). Journal output:

```bash
journalctl -u me-autodeploy -n 100
sudo systemctl start me-autodeploy.service   # deploy now, don't wait for the timer
systemctl list-timers me-autodeploy.timer    # next run
```

The units are versioned in `deploy/systemd/` and (re)installed by `deploy.sh`;
`SKIP_SYSTEMD=1` skips that step.

## DNS cutover (www / GitHub Pages → this server)

The repo still has a `CNAME` (now `me.ondralinek.cz`) so GitHub Pages keeps a
usable copy of the site. The live host is this server:

| Type | Name | Value |
|---|---|---|
| A | me.ondralinek.cz | `2.31.33.21` |
| AAAA | me.ondralinek.cz | `2a01:4f8:c016:e828::1` |

`www.ondralinek.cz` is not part of this site any more: it serves the landing
page at `ondralinek.cz`. The certificate for this host therefore contains only
`me.ondralinek.cz`; reissue it with `./deploy/enable-tls.sh` if the old SAN is
still present. The MX and other mail records on `ondralinek.cz` are untouched.

DNS is managed at WebSupport (`ns1.websupport.cz`).

## TLS

```bash
sudo certbot certificates                 # current state
sudo certbot renew --dry-run
```

Run the cutover script only after DNS points here:

```bash
cd ~/me
./deploy/enable-tls.sh
```

It checks both names via public resolvers, requests the certificate with the
**webroot** authenticator (`-w /var/www/me`, so the versioned vhost is never
rewritten), installs `deploy/nginx/me.conf` and verifies both schemes.
`deploy/deploy.sh` keeps the ACME challenge directory intact and selects the
HTTP or HTTPS vhost depending on whether the certificate exists.

## Verification

```bash
curl -sSI https://me.ondralinek.cz/ | head -8
curl -sSI https://me.ondralinek.cz/css/style.css | grep -i cache-control
curl -sSI http://me.ondralinek.cz/ | grep -i location          # -> https
```

## Rollback

The GitHub Pages site in this repository is kept in sync, so the rollback is
a DNS change back to GitHub Pages (`CNAME ondrej-li.github.io`). Stop the
timer first so the server does not keep publishing:

```bash
sudo systemctl disable --now me-autodeploy.timer
```
