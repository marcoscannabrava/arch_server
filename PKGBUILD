# Maintainer: Marcos
pkgname=home-server
pkgver=1.0.0
pkgrel=1
pkgdesc="Meta-package for a simple home server with Caddy, Docker, and SSH"
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
  'curl'
  'jq'
)
install=home-server.install
source=(
  'home-server-setup'
  'cloudflare-ddns'
  'cloudflare-ddns.conf.example'
  'cloudflare-ddns.service'
  'cloudflare-ddns.timer'
)
sha256sums=('SKIP' 'SKIP' 'SKIP' 'SKIP' 'SKIP')

package() {
  install -Dm755 "$srcdir/home-server-setup" "$pkgdir/usr/bin/home-server-setup"
  install -Dm755 "$srcdir/cloudflare-ddns" "$pkgdir/usr/bin/cloudflare-ddns"
  install -Dm644 "$srcdir/cloudflare-ddns.conf.example" \
    "$pkgdir/etc/home-server/cloudflare-ddns.conf.example"
  install -Dm644 "$srcdir/cloudflare-ddns.service" \
    "$pkgdir/usr/lib/systemd/system/cloudflare-ddns.service"
  install -Dm644 "$srcdir/cloudflare-ddns.timer" \
    "$pkgdir/usr/lib/systemd/system/cloudflare-ddns.timer"
}
