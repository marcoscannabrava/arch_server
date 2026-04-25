# home-server

A small Arch Linux meta-package and helper scripts that turn a fresh
machine into a personal home server. It bundles:

- **Caddy** — TLS-terminating reverse proxy with automatic Let's Encrypt
  certificates, serving a static site at the apex domain and dispatching
  `<app>.<domain>` to docker-deployed apps.
- **Docker + Docker Compose** — for running the apps themselves.
- **OpenSSH** — remote access.
- **Cloudflare Dynamic DNS** — keeps DNS records pointed at the box's
  current public IP via a systemd timer.
- **NanoClaw bootstrap** — one command to clone and install the
  [NanoClaw](https://github.com/qwibitai/nanoclaw) agent runtime.

The reference deployment in this README assumes the domain `m4s.dev`,
but the package itself is parametric: `home-server-setup` prompts for
your domain and substitutes it everywhere.

## What you get

```
                                  ┌──────────────────────┐
       https://m4s.dev    ───────▶│                      │
       https://www.m4s.dev───────▶│ apex/www static site │  /srv/home-server/site
                                  │                      │
                                  ├──────────────────────┤
       https://<app>.m4s.dev ────▶│ Caddy reverse proxy  │──▶ 127.0.0.1:<port>
                                  │ (per-app snippets)   │   (your docker compose stack)
                                  └──────────────────────┘
```

- `m4s.dev` and `www.m4s.dev` both resolve to the box; `www` redirects
  permanently to the apex.
- Each docker app gets its own subdomain `<name>.m4s.dev`, its own
  directory under `/srv/home-server/apps/<name>/`, and its own Caddy
  snippet under `/etc/caddy/apps/<name>.caddy`.
- A separate systemd timer keeps the Cloudflare A records for
  `m4s.dev` and `www.m4s.dev` updated whenever the box's public IP
  changes.

## Layout on disk

| Path | Purpose |
|---|---|
| `/usr/bin/home-server-setup` | One-time setup wizard |
| `/usr/bin/home-server-add-app` | Add a new docker-deployed app |
| `/usr/bin/home-server-nanoclaw` | Bootstrap a NanoClaw instance |
| `/usr/bin/cloudflare-ddns` | DDNS update script (run by the timer) |
| `/usr/share/home-server/Caddyfile.template` | Source template for `/etc/caddy/Caddyfile` |
| `/usr/share/home-server/index.html` | Default static site page |
| `/etc/caddy/Caddyfile` | Active Caddy config |
| `/etc/caddy/apps/*.caddy` | Per-app reverse proxy snippets (imported by Caddyfile) |
| `/etc/home-server/config` | `DOMAIN=m4s.dev` (read by the helpers) |
| `/etc/home-server/cloudflare-ddns.conf` | DDNS credentials (mode 600) |
| `/etc/home-server/cloudflare-ddns.conf.example` | Template config |
| `/srv/home-server/site/` | Static site web root (apex + www) |
| `/srv/home-server/apps/<name>/` | Per-app working directory (compose file goes here) |
| `/srv/home-server/nanoclaw/` | NanoClaw clone, when installed |
| `/var/lib/home-server/cloudflare-ddns.ip` | Last-known public IP (DDNS state) |

## Building and installing

The package builds with `makepkg`. A Docker-based smoke test is
included:

```sh
docker build -t home-server-pkg .
docker run --rm home-server-pkg          # runs makepkg
```

To install on the actual host:

```sh
makepkg -si
```

The `home-server` package depends on `caddy`, `docker`, `docker-compose`,
`openssh`, `nodejs`, `npm`, `git`, `curl`, and `jq`.

## Initial setup

Run the wizard once after install:

```sh
home-server-setup
```

It prompts for:

1. Your domain (e.g. `m4s.dev`).
2. A Cloudflare API token, zone ID, and the records to keep updated
   (defaults to `<domain>,www.<domain>`). Leave the token blank to
   skip DDNS configuration.

Then it:

- Writes `/etc/home-server/config` with `DOMAIN=<your-domain>`.
- Creates `/srv/home-server/{site,apps}` and `/etc/caddy/apps/`.
- Copies the default `index.html` into the site root.
- Renders `/etc/caddy/Caddyfile` from the template.
- Enables and starts `sshd`, `docker`, `caddy`, and (if configured)
  `cloudflare-ddns.timer`.

Caddy obtains TLS certificates from Let's Encrypt automatically on
first request, so make sure your DNS records resolve to this box and
ports 80 and 443 reach it before the first request.

## DNS

You need at least these records pointing at the server's public IP:

| Name | Type | Value | Managed by DDNS? |
|---|---|---|---|
| `m4s.dev` | A | <public-ip> | yes (default) |
| `www.m4s.dev` | A | <public-ip> | yes (default) |
| `<app>.m4s.dev` | A | <public-ip> | optional — add to `CF_RECORDS` if you want them updated automatically |

A wildcard `*.m4s.dev → <ip>` record also works and is convenient if
you add many apps; in that case you only need DDNS to track the
wildcard's parent records.

## Static site (apex + www)

The static site is served at `m4s.dev` (and `www.m4s.dev` redirects to
it) from `/srv/home-server/site/`. Drop whatever HTML/CSS/JS you want
in that directory. The default `index.html` shipped with the package
is just a placeholder.

To replace the site:

```sh
sudo rm -rf /srv/home-server/site
sudo mkdir -p /srv/home-server/site
sudo cp -r /path/to/your/site/. /srv/home-server/site/
sudo systemctl reload caddy   # only needed if you change Caddyfile
```

The Caddyfile uses `encode zstd gzip` so static assets are served
compressed.

## Adding a docker app

The pattern is: app listens on a local port, Caddy reverse-proxies a
subdomain to it.

```sh
home-server-add-app <name> <port>
```

For example, to expose Grafana on `grafana.m4s.dev`:

```sh
home-server-add-app grafana 3000
```

This:

1. Validates `<name>` (lowercase letters, digits, hyphens) and `<port>`
   (1–65535).
2. Creates `/srv/home-server/apps/grafana/` for your compose file.
3. Writes `/etc/caddy/apps/grafana.caddy`:
   ```caddy
   grafana.m4s.dev {
       reverse_proxy 127.0.0.1:3000
   }
   ```
4. Validates the full Caddyfile (rolls back the snippet if it fails).
5. Reloads Caddy.

Then drop a `docker-compose.yml` in the new app directory. **The app
must publish its port on `127.0.0.1` (not `0.0.0.0`)** so it's only
reachable through Caddy. Example:

```yaml
# /srv/home-server/apps/grafana/docker-compose.yml
services:
  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
    volumes:
      - data:/var/lib/grafana

volumes:
  data:
```

Bring it up manually:

```sh
cd /srv/home-server/apps/grafana
sudo docker compose up -d
```

### Autostart on boot

A template unit `docker-compose@.service` ships with the package.
Enable it for an app to have it brought up at boot (and brought down
on shutdown):

```sh
sudo systemctl enable --now docker-compose@grafana.service
```

You can also pass `--enable` to `home-server-add-app` and it will
enable the unit immediately if a compose file is already present.

### Removing an app

```sh
sudo systemctl disable --now docker-compose@<name>.service 2>/dev/null || true
cd /srv/home-server/apps/<name> && sudo docker compose down
sudo rm /etc/caddy/apps/<name>.caddy
sudo systemctl reload caddy
sudo rm -rf /srv/home-server/apps/<name>     # if you want the data gone
```

## Cloudflare Dynamic DNS

The `cloudflare-ddns.timer` runs `cloudflare-ddns` every five minutes
(plus once a minute after boot, with `Persistent=true` so missed runs
catch up). It:

1. Reads `/etc/home-server/cloudflare-ddns.conf`.
2. Fetches the current public IPv4 (`api.ipify.org`, with `ifconfig.me`
   as fallback).
3. Compares against the cached value at
   `/var/lib/home-server/cloudflare-ddns.ip`.
4. If changed, PATCHes each `A` record listed in `CF_RECORDS` via the
   Cloudflare API and updates the cache.

The script never **creates** records — they must already exist in your
zone. Configure with:

```ini
# /etc/home-server/cloudflare-ddns.conf  (mode 600)
CF_API_TOKEN=<token with Zone:DNS:Edit on this zone>
CF_ZONE_ID=<zone id from the Cloudflare dashboard>
CF_RECORDS=m4s.dev,www.m4s.dev
```

Useful commands:

```sh
sudo systemctl list-timers cloudflare-ddns.timer
sudo systemctl start cloudflare-ddns.service       # force a run now
journalctl -u cloudflare-ddns -n 50 --no-pager
```

## NanoClaw

[NanoClaw](https://github.com/qwibitai/nanoclaw) is an AI assistant
that runs Claude agents inside per-agent Docker containers and pairs
them to messaging channels (Telegram, Discord, WhatsApp, …).

To install:

```sh
home-server-nanoclaw
```

This clones (or `git pull`s) the repo to `/srv/home-server/nanoclaw`
and execs `bash nanoclaw.sh`, which is the upstream interactive
installer. It will prompt for your Anthropic credential and walk you
through pairing your first channel.

NanoClaw doesn't expose a public HTTP endpoint by default, so the
helper does **not** create a Caddy snippet. If you later expose a web
UI on a local port, just register it like any other app:

```sh
home-server-add-app nanoclaw <port>
```

To re-run the upstream installer (to add channels, providers, etc.):

```sh
cd /srv/home-server/nanoclaw && bash nanoclaw.sh
```

## Caddy details

`/etc/caddy/Caddyfile` after setup is roughly:

```caddy
m4s.dev {
    root * /srv/home-server/site
    file_server
    encode zstd gzip
}

www.m4s.dev {
    redir https://m4s.dev{uri} permanent
}

import /etc/caddy/apps/*.caddy
```

The `import` directive pulls in every `.caddy` file under
`/etc/caddy/apps/`, so adding or removing an app is a matter of
adding/removing a snippet and reloading caddy. To inspect the
effective config:

```sh
sudo caddy adapt --config /etc/caddy/Caddyfile --pretty
```

To validate after manual edits:

```sh
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

## Troubleshooting

**Caddy fails to obtain a certificate.** Make sure the DNS record
resolves to this box, ports 80 and 443 are open and reaching this
host, and nothing else is listening on them. `journalctl -u caddy`
will have the details from the ACME challenge.

**App is up but the subdomain returns 502.** The app is listening on
`0.0.0.0` or a different port than the Caddy snippet. Check with
`ss -ltnp | grep <port>` and confirm the snippet's port matches and
that the app is bound to `127.0.0.1`.

**DDNS records aren't updating.** Run `sudo systemctl start
cloudflare-ddns` once and check `journalctl -u cloudflare-ddns`.
Common causes: API token missing the `Zone:DNS:Edit` permission for
the zone, wrong `CF_ZONE_ID`, or a record name in `CF_RECORDS` that
doesn't exist yet (the script refuses to create records).

**`home-server-add-app` rolls back with "Caddyfile failed validation".**
Two snippets bound to the same hostname will collide, as will syntax
errors in adjacent snippets. Run
`sudo caddy validate --config /etc/caddy/Caddyfile` directly to see
the parser error.

## Development

Iterate on the package with the included Docker harness:

```sh
docker build -t home-server-pkg . && docker run --rm home-server-pkg
```

`makepkg` runs as the unprivileged `builder` user inside the container
and produces a `.pkg.tar.zst` artifact, exercising the same build path
as the host. To inspect the package contents:

```sh
docker run --rm --entrypoint bash home-server-pkg \
  -c 'makepkg -s --noconfirm >/dev/null 2>&1 && tar -tf home-server-*.pkg.tar.zst'
```
