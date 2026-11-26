# CLAUDE.md — me.ondralinek.cz

The static personal site. Plain HTML, CSS, JS and images; no build step, no
backend. [`deploy/DEPLOY.md`](deploy/DEPLOY.md) is the deployment map (host, web
root, vhost, headers, TLS, the autodeploy timer).

## Layout

| Path | What |
|---|---|
| `index.html` | the landing page, one long page with sections |
| `clip.html` | a utility page: a scratch pad kept in `localStorage` plus notes worth reaching from any machine |
| `css/style.css` | the compiled theme (from `_scss/`, committed as CSS) |
| `css/site.css`, `css/dark.css` | site-specific additions and the dark-mode overrides |
| `css/clip.css` | styles for `clip.html`, self-contained with its own light/dark variables |
| `js/main.js`, `js/clip.js` | the landing page's behaviour, and the clip page's copy buttons + scratch pad |
| `_scss/` | the source of `css/style.css` (SASS, compiled outside the repo) |
| `images/`, `fonts/` | assets; `images/favicon.png` is referenced from every page |
| `deploy/` | nginx vhost + headers, `deploy.sh`, `autodeploy.sh` (the VPS timer) |

## Building

Nothing to build — the files are the site. Preview with any static server:

```sh
python3 -m http.server 8000        # then http://127.0.0.1:8000/
```

There is no test suite and no CI. Verification is: open the page, in both colour
modes (the mode lives in `localStorage['ondralinek-mode']` and drives
`<html data-theme>`) and at a phone width.

## Deploy

`me-autodeploy.timer` on `deploy@ondralinek.cz` pulls `master` every five minutes
and rsyncs into `/var/www/me`, then reloads nginx if the vhost changed. Pushing to
`master` is the deploy; there is no staging.

## Conventions

- The CSP is strict (`default-src 'self'`, no external origins except the two
  Google Fonts/CDN entries in `deploy/nginx/me-headers.conf`). Anything new must
  come from `self` — no new CDN, no inline `<style>`/`<script>` unless it matches
  what those headers already allow.
- Keep pages self-contained. `clip.html` deliberately does not depend on
  `css/style.css`, so it renders even if the theme changes.
- Colour mode: never hard-code a background or text colour; use the CSS variables
  in `css/clip.css` / `css/dark.css` so both modes stay readable.
- No analytics, no cookies, no third-party requests beyond the fonts already
  declared.
- Anything that must survive `rsync --delete` belongs in the repo, not on the box.

## Before this site goes live

This repository is served publicly at https://me.ondralinek.cz. A change that adds or alters a
page, a form, a script, a header or a vhost passes the launch gate before it
ships:

```sh
web-launch-check https://me.ondralinek.cz
```

- `FAIL` blocks the publish; `WARN` is a decision to state in the reply, not
  something to leave unmentioned.
- The `web-launch-checklist` skill has the 25 items the checker cannot judge:
  privacy and terms content, colour contrast, real-device speed, spam
  protection, analytics and error monitoring, one clear call to action, and the
  signup/login/reset flows.
- Run it again after publishing: it checks the live vhost, headers and
  certificate, not the working tree.
- A preview vhost passes the same gate before DNS moves.

## Deploying this site

https://me.ondralinek.cz is published by the **deploy** account from this repository's
`master` branch — the `site-deploy` timer, every five minutes. Merge is
deploy: there is no publish command, and `sudo vps-site publish` refuses this
web root (one writer per root, and it is not this account).

Verify after merging, and give it up to ten minutes:

```sh
site-status --site me
curl -fsS https://me.ondralinek.cz/deployed.json           # {"commit": "...", "deployed_at": "..."}
git -C ~/repos/www rev-parse origin/master
```

The three commits must match. If it has not moved after two timer cycles, read
`journalctl -u site-deploy -n 50`, report the commit that should be live and the
one that is, and do not rsync into `/var/www` or edit a live file to compensate.
The `static-site-deploy` skill has the full procedure.

## Writing HTML and CSS

Before writing or changing HTML, CSS or client-side JavaScript here, use the
`modern-web-guidance` skill (installed for this account): search for the
capability, retrieve the guides it names, apply them. The platform usually has
the answer the library was added for — `<dialog>` and the popover API instead of
div overlays, container queries instead of media-query rewrites, View
Transitions and `@starting-style` instead of JS entrance animations, native
validation and `:user-invalid` instead of a validation library.

Browser support policy: Baseline Widely available as-is; Newly available only
with feature detection and a fallback of 20 lines or fewer, no dependencies, no
polyfills.
