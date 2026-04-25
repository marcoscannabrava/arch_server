# Maintainer: Marcos
pkgname=home-server
pkgver=1.0.0
pkgrel=1
pkgdesc="Meta-package for a simple home server with Caddy, Docker, SSH, and Cloudflare DDNS"
arch=('any')
url="https://github.com/marcos/home-server"
license=('MIT')
depends=(
  'caddy'
  'docker'
  'docker-compose'
  'openssh'
  'nodejs'
  'npm'
  'git'
  'curl'
  'jq'
)
install=home-server.install
source=(
  'home-server-setup'
  'home-server-add-app'
  'home-server-nanoclaw'
  'Caddyfile.template'
  'index.html'
  'cloudflare-ddns'
  'cloudflare-ddns.conf.example'
  'cloudflare-ddns.service'
  'cloudflare-ddns.timer'
  'docker-compose@.service'
)
sha256sums=(
  'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP'
  'SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP'
)

package() {
  # Executables
  install -Dm755 "$srcdir/home-server-setup"    "$pkgdir/usr/bin/home-server-setup"
  install -Dm755 "$srcdir/home-server-add-app"  "$pkgdir/usr/bin/home-server-add-app"
  install -Dm755 "$srcdir/home-server-nanoclaw" "$pkgdir/usr/bin/home-server-nanoclaw"
  install -Dm755 "$srcdir/cloudflare-ddns"      "$pkgdir/usr/bin/cloudflare-ddns"

  # Templates / static assets used by the setup script
  install -Dm644 "$srcdir/Caddyfile.template" "$pkgdir/usr/share/home-server/Caddyfile.template"
  install -Dm644 "$srcdir/index.html"         "$pkgdir/usr/share/home-server/index.html"

  # Config example
  install -Dm644 "$srcdir/cloudflare-ddns.conf.example" \
    "$pkgdir/etc/home-server/cloudflare-ddns.conf.example"

  # systemd units
  install -Dm644 "$srcdir/cloudflare-ddns.service" \
    "$pkgdir/usr/lib/systemd/system/cloudflare-ddns.service"
  install -Dm644 "$srcdir/cloudflare-ddns.timer" \
    "$pkgdir/usr/lib/systemd/system/cloudflare-ddns.timer"
  install -Dm644 "$srcdir/docker-compose@.service" \
    "$pkgdir/usr/lib/systemd/system/docker-compose@.service"
}
