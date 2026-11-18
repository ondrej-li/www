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
